import SwiftUI

struct AppShell: View {
    @EnvironmentObject private var store: NotebookStore
    @EnvironmentObject private var serverSettings: ServerSettings
    @State private var selectedFolderID: UUID?
    @State private var showingSettings = false
    @State private var showingGraph = false

    var body: some View {
        NavigationSplitView {
            LibrarySidebar(selectedFolderID: $selectedFolderID, showingSettings: $showingSettings)
                .toolbar {
                    ToolbarItem(placement: .bottomBar) {
                        Button { showingGraph = true } label: { Label("Graphing", systemImage: "chart.xyaxis.line") }
                    }
                }
        } detail: {
            VStack(spacing: 0) {
                if !store.openNotebookIDs.isEmpty { tabBar }
                if let selected = store.selectedNotebookID {
                    NotebookEditorView(notebookID: selected).id(selected)
                } else {
                    NavigationStack { NotebookLibraryView(selectedFolderID: selectedFolderID) }
                }
            }
        }
        .sheet(isPresented: $showingSettings) { ServerSettingsView() }
        .sheet(isPresented: $showingGraph) { GraphView() }
        .onChange(of: selectedFolderID) { _, _ in store.selectedNotebookID = nil }
    }

    private var tabBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4) {
                Button { store.selectedNotebookID = nil } label: { Image(systemName: "square.grid.2x2") }
                    .buttonStyle(.bordered)
                ForEach(store.openNotebookIDs, id: \.self) { id in
                    if let notebook = store.notebooks.first(where: { $0.id == id }) {
                        HStack(spacing: 6) {
                            Button(notebook.title) { store.selectedNotebookID = id }
                                .lineLimit(1)
                            Button { store.close(id) } label: { Image(systemName: "xmark") }
                                .buttonStyle(.plain).foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 10).padding(.vertical, 7)
                        .background(store.selectedNotebookID == id ? Color.indigo.opacity(0.16) : .clear, in: Capsule())
                    }
                }
            }.padding(.horizontal, 10).padding(.vertical, 5)
        }.background(.bar)
    }
}
