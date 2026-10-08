import SwiftUI

struct LibrarySidebar: View {
    @EnvironmentObject private var store: NotebookStore
    @Binding var selectedFolderID: UUID?
    @Binding var showingSettings: Bool
    @State private var newFolderName = ""
    @State private var showingNewFolder = false

    var body: some View {
        List {
            Section {
                Button { selectedFolderID = nil } label: {
                    Label("All Notebooks", systemImage: "books.vertical")
                }
                Button { selectedFolderID = nil } label: {
                    Label("Recent", systemImage: "clock")
                }
            }
            Section("Folders") {
                ForEach(store.folders.filter { $0.parentID == nil }) { folder in
                    FolderRow(folder: folder, selectedFolderID: $selectedFolderID)
                }
                Button { showingNewFolder = true } label: {
                    Label("New Folder", systemImage: "folder.badge.plus")
                }
            }
            Section {
                Button { showingSettings = true } label: {
                    Label("AI Server", systemImage: "server.rack")
                }
            }
        }
        .navigationTitle("Derive")
        .alert("New Folder", isPresented: $showingNewFolder) {
            TextField("Folder name", text: $newFolderName)
            Button("Create") {
                guard !newFolderName.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                store.createFolder(name: newFolderName)
                newFolderName = ""
            }
            Button("Cancel", role: .cancel) {}
        }
    }
}

private struct FolderRow: View {
    @EnvironmentObject private var store: NotebookStore
    let folder: NotebookFolder
    @Binding var selectedFolderID: UUID?
    @State private var showingNewChild = false
    @State private var showingRename = false
    @State private var input = ""

    var children: [NotebookFolder] { store.folders.filter { $0.parentID == folder.id } }

    var body: some View {
        if children.isEmpty {
            Button { selectedFolderID = folder.id } label: {
                Label(folder.name, systemImage: "folder.fill").foregroundStyle(Color(hex: folder.colourHex))
            }
            .modifier(FolderActions(folder: folder, input: $input, showingNewChild: $showingNewChild, showingRename: $showingRename))
        } else {
            DisclosureGroup {
                ForEach(children) { FolderRow(folder: $0, selectedFolderID: $selectedFolderID) }
            } label: {
                Button { selectedFolderID = folder.id } label: {
                    Label(folder.name, systemImage: "folder.fill").foregroundStyle(Color(hex: folder.colourHex))
                }
            }
            .modifier(FolderActions(folder: folder, input: $input, showingNewChild: $showingNewChild, showingRename: $showingRename))
        }
    }
}

private struct FolderActions: ViewModifier {
    @EnvironmentObject private var store: NotebookStore
    let folder: NotebookFolder
    @Binding var input: String
    @Binding var showingNewChild: Bool
    @Binding var showingRename: Bool

    func body(content: Content) -> some View {
        content
            .dropDestination(for: String.self) { items, _ in
                guard let value = items.first, let id = UUID(uuidString: value) else { return false }
                store.moveNotebook(id, to: folder.id)
                return true
            }
            .contextMenu {
                Button("New Subfolder") { input = ""; showingNewChild = true }
                Button("Rename") { input = folder.name; showingRename = true }
                Menu("Colour") {
                    Button("Indigo") { store.setFolderColour(folder.id, hex: "5B6EF5") }
                    Button("Blue") { store.setFolderColour(folder.id, hex: "2997FF") }
                    Button("Green") { store.setFolderColour(folder.id, hex: "34C759") }
                    Button("Orange") { store.setFolderColour(folder.id, hex: "FF9500") }
                }
                Button("Delete", role: .destructive) { store.deleteFolder(folder.id) }
            }
            .alert("New Subfolder", isPresented: $showingNewChild) {
                TextField("Name", text: $input)
                Button("Create") { if !input.isEmpty { store.createFolder(name: input, parentID: folder.id) } }
                Button("Cancel", role: .cancel) {}
            }
            .alert("Rename Folder", isPresented: $showingRename) {
                TextField("Name", text: $input)
                Button("Save") { if !input.isEmpty { store.renameFolder(folder.id, to: input) } }
                Button("Cancel", role: .cancel) {}
            }
    }
}

private extension Color {
    init(hex: String) {
        let value = UInt64(hex, radix: 16) ?? 0x5B6EF5
        self.init(
            red: Double((value >> 16) & 255) / 255,
            green: Double((value >> 8) & 255) / 255,
            blue: Double(value & 255) / 255
        )
    }
}
