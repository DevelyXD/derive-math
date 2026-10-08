import Foundation
import PDFKit

@MainActor
final class NotebookStore: ObservableObject {
    @Published private(set) var folders: [NotebookFolder] = []
    @Published private(set) var notebooks: [Notebook] = []
    @Published var openNotebookIDs: [UUID] = []
    @Published var selectedNotebookID: UUID?

    private let fileURL: URL
    private var saveTask: Task<Void, Never>?

    init() {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let directory = support.appendingPathComponent("DeriveMath", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        fileURL = directory.appendingPathComponent("library.json")
        load()
        openNotebookIDs = UserDefaults.standard.stringArray(forKey: "openNotebookIDs")?.compactMap(UUID.init) ?? []
        openNotebookIDs.removeAll { id in !notebooks.contains { $0.id == id } }
        selectedNotebookID = openNotebookIDs.last
    }

    func createNotebook(in folderID: UUID? = nil, title: String = "Untitled Notebook") {
        let notebook = Notebook(title: title, folderID: folderID)
        notebooks.insert(notebook, at: 0)
        open(notebook.id)
        scheduleSave()
    }

    func createFolder(name: String, parentID: UUID? = nil) {
        folders.append(NotebookFolder(name: name, parentID: parentID))
        scheduleSave()
    }

    func renameFolder(_ id: UUID, to name: String) {
        guard let index = folders.firstIndex(where: { $0.id == id }) else { return }
        folders[index].name = name
        scheduleSave()
    }

    func setFolderColour(_ id: UUID, hex: String) {
        guard let index = folders.firstIndex(where: { $0.id == id }) else { return }
        folders[index].colourHex = hex
        scheduleSave()
    }

    func renameNotebook(_ id: UUID, to title: String) {
        mutateNotebook(id) { $0.title = title }
    }

    func deleteNotebook(_ id: UUID) {
        notebooks.removeAll { $0.id == id }
        openNotebookIDs.removeAll { $0 == id }
        selectedNotebookID = openNotebookIDs.last
        rememberTabs()
        scheduleSave()
    }

    func duplicateNotebook(_ id: UUID) {
        guard var copy = notebooks.first(where: { $0.id == id }) else { return }
        copy.id = UUID()
        copy.title += " Copy"
        copy.createdAt = Date()
        copy.modifiedAt = Date()
        copy.pages = copy.pages.map { page in
            var page = page
            page.id = UUID()
            return page
        }
        copy.currentPageID = copy.pages.first?.id
        notebooks.insert(copy, at: 0)
        open(copy.id)
        scheduleSave()
    }

    func moveNotebook(_ id: UUID, to folderID: UUID?) {
        mutateNotebook(id) { $0.folderID = folderID }
    }

    func deleteFolder(_ id: UUID) {
        let descendants = descendantFolderIDs(of: id).union([id])
        for index in notebooks.indices where notebooks[index].folderID.map(descendants.contains) == true {
            notebooks[index].folderID = nil
        }
        folders.removeAll { descendants.contains($0.id) }
        scheduleSave()
    }

    func open(_ id: UUID) {
        guard notebooks.contains(where: { $0.id == id }) else { return }
        if !openNotebookIDs.contains(id) { openNotebookIDs.append(id) }
        selectedNotebookID = id
        rememberTabs()
    }

    func close(_ id: UUID) {
        openNotebookIDs.removeAll { $0 == id }
        if selectedNotebookID == id { selectedNotebookID = openNotebookIDs.last }
        rememberTabs()
    }

    func addPage(to notebookID: UUID, template: PageTemplate) {
        mutateNotebook(notebookID) { notebook in
            let page = NotebookPage(title: "Page \(notebook.pages.count + 1)", template: template)
            notebook.pages.append(page)
            notebook.currentPageID = page.id
        }
    }

    func selectPage(_ pageID: UUID, in notebookID: UUID) {
        mutateNotebook(notebookID) { $0.currentPageID = pageID }
    }

    func deletePage(_ pageID: UUID, in notebookID: UUID) {
        mutateNotebook(notebookID) { notebook in
            guard notebook.pages.count > 1 else { return }
            notebook.pages.removeAll { $0.id == pageID }
            notebook.currentPageID = notebook.pages.first?.id
        }
    }

    func updateDrawing(_ data: Data, pageID: UUID, notebookID: UUID) {
        mutateNotebook(notebookID) { notebook in
            guard let index = notebook.pages.firstIndex(where: { $0.id == pageID }) else { return }
            notebook.pages[index].drawingData = data
        }
    }

    func importPDF(from url: URL, into folderID: UUID?) throws {
        let accessing = url.startAccessingSecurityScopedResource()
        defer { if accessing { url.stopAccessingSecurityScopedResource() } }
        let data = try Data(contentsOf: url)
        guard let document = PDFDocument(data: data), document.pageCount > 0 else {
            throw CocoaError(.fileReadCorruptFile)
        }
        let pages = (0..<document.pageCount).map {
            NotebookPage(title: "Page \($0 + 1)", template: .pdf, pdfPageIndex: $0)
        }
        let notebook = Notebook(
            title: url.deletingPathExtension().lastPathComponent,
            folderID: folderID,
            pages: pages,
            currentPageID: pages.first?.id,
            pdfData: data
        )
        notebooks.insert(notebook, at: 0)
        open(notebook.id)
        scheduleSave()
    }

    func saveNow() {
        do {
            let data = try JSONEncoder().encode(LibraryState(folders: folders, notebooks: notebooks))
            try data.write(to: fileURL, options: [.atomic, .completeFileProtection])
        } catch {
            assertionFailure("Notebook save failed: \(error)")
        }
    }

    private func mutateNotebook(_ id: UUID, mutation: (inout Notebook) -> Void) {
        guard let index = notebooks.firstIndex(where: { $0.id == id }) else { return }
        mutation(&notebooks[index])
        notebooks[index].modifiedAt = Date()
        scheduleSave()
    }

    private func scheduleSave() {
        saveTask?.cancel()
        saveTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(400))
            guard !Task.isCancelled else { return }
            self?.saveNow()
        }
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let state = try? JSONDecoder().decode(LibraryState.self, from: data) else { return }
        folders = state.folders
        notebooks = state.notebooks
    }

    private func rememberTabs() {
        UserDefaults.standard.set(openNotebookIDs.map(\.uuidString), forKey: "openNotebookIDs")
    }

    private func descendantFolderIDs(of id: UUID) -> Set<UUID> {
        let children = folders.filter { $0.parentID == id }.map(\.id)
        return children.reduce(into: Set(children)) { result, child in
            result.formUnion(descendantFolderIDs(of: child))
        }
    }
}
