import SwiftUI
import UniformTypeIdentifiers

struct NotebookLibraryView: View {
    @EnvironmentObject private var store: NotebookStore
    let selectedFolderID: UUID?
    @State private var query = ""
    @State private var importingPDF = false
    @State private var importError: String?

    private var visibleNotebooks: [Notebook] {
        store.notebooks
            .filter { selectedFolderID == nil || $0.folderID == selectedFolderID }
            .filter { query.isEmpty || $0.title.localizedCaseInsensitiveContains(query) }
            .sorted { $0.modifiedAt > $1.modifiedAt }
    }

    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 210), spacing: 18)], spacing: 18) {
                Button { store.createNotebook(in: selectedFolderID) } label: {
                    VStack(spacing: 14) {
                        Image(systemName: "plus.circle.fill").font(.system(size: 40))
                        Text("New Notebook").font(.headline)
                    }
                    .frame(maxWidth: .infinity, minHeight: 160)
                    .background(.indigo.opacity(0.1), in: RoundedRectangle(cornerRadius: 18))
                }
                ForEach(visibleNotebooks) { notebook in
                    Button { store.open(notebook.id) } label: {
                        VStack(alignment: .leading, spacing: 10) {
                            Image(systemName: notebook.pdfData == nil ? "book.closed.fill" : "doc.richtext.fill")
                                .font(.system(size: 34)).foregroundStyle(.indigo)
                            Spacer()
                            Text(notebook.title).font(.headline).lineLimit(2)
                            Text("\(notebook.pages.count) page\(notebook.pages.count == 1 ? "" : "s")")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                        .padding().frame(maxWidth: .infinity, minHeight: 160, alignment: .leading)
                        .background(.background, in: RoundedRectangle(cornerRadius: 18))
                        .shadow(color: .black.opacity(0.08), radius: 8, y: 3)
                    }
                    .buttonStyle(.plain)
                    .draggable(notebook.id.uuidString)
                    .contextMenu {
                        Button("Duplicate") { store.duplicateNotebook(notebook.id) }
                        Menu("Move to Folder") {
                            Button("No Folder") { store.moveNotebook(notebook.id, to: nil) }
                            ForEach(store.folders) { folder in
                                Button(folder.name) { store.moveNotebook(notebook.id, to: folder.id) }
                            }
                        }
                        Button("Delete", role: .destructive) { store.deleteNotebook(notebook.id) }
                    }
                }
            }.padding(24)
        }
        .background(Color(uiColor: .secondarySystemBackground))
        .navigationTitle(selectedFolderID.flatMap { id in store.folders.first { $0.id == id }?.name } ?? "Notebooks")
        .searchable(text: $query)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button { importingPDF = true } label: { Label("Import PDF", systemImage: "square.and.arrow.down") }
                Button { store.createNotebook(in: selectedFolderID) } label: { Label("New Notebook", systemImage: "plus") }
            }
        }
        .fileImporter(isPresented: $importingPDF, allowedContentTypes: [.pdf]) { result in
            do { try store.importPDF(from: result.get(), into: selectedFolderID) }
            catch { importError = error.localizedDescription }
        }
        .alert("Could Not Import PDF", isPresented: Binding(get: { importError != nil }, set: { if !$0 { importError = nil } })) {
            Button("OK") { importError = nil }
        } message: { Text(importError ?? "Unknown error") }
    }
}
