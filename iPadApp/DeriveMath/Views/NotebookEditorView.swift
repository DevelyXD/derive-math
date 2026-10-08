import PencilKit
import SwiftUI

struct NotebookEditorView: View {
    @EnvironmentObject private var store: NotebookStore
    let notebookID: UUID
    @State private var tool: DrawingTool = .pen
    @State private var inkColour = Color.primary
    @State private var width = 3.0
    @State private var canvasUndoManager: UndoManager?
    @State private var showingAssistant = false
    @State private var exporting = false
    @State private var showingRename = false
    @State private var titleDraft = ""

    private var notebook: Notebook? { store.notebooks.first { $0.id == notebookID } }
    private var selectedPage: NotebookPage? {
        guard let notebook else { return nil }
        return notebook.pages.first { $0.id == notebook.selectedPageID } ?? notebook.pages.first
    }

    var body: some View {
        if let notebook, let page = selectedPage {
            VStack(spacing: 0) {
                toolBar(notebook: notebook, page: page)
                HStack(spacing: 0) {
                    pageStrip(notebook: notebook)
                    ZStack {
                        PageBackground(template: page.template, pdfData: notebook.pdfData, pdfPageIndex: page.pdfPageIndex)
                        DrawingCanvas(
                            drawingData: drawingBinding(pageID: page.id),
                            canvasUndoManager: $canvasUndoManager,
                            tool: tool,
                            colour: UIColor(inkColour),
                            width: width
                        )
                    }
                    .aspectRatio(0.75, contentMode: .fit)
                    .padding(18)
                    .background(Color(uiColor: .secondarySystemBackground))
                }
            }
            .navigationTitle(notebook.title)
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingAssistant) { MathAssistantView() }
            .alert("Rename Notebook", isPresented: $showingRename) {
                TextField("Name", text: $titleDraft)
                Button("Save") { if !titleDraft.isEmpty { store.renameNotebook(notebook.id, to: titleDraft) } }
                Button("Cancel", role: .cancel) {}
            }
            .fileExporter(
                isPresented: $exporting,
                document: NotebookPDFDocument(notebook: notebook),
                contentType: .pdf,
                defaultFilename: notebook.title
            ) { _ in }
        } else {
            ContentUnavailableView("Notebook unavailable", systemImage: "book.closed")
        }
    }

    @ViewBuilder private func toolBar(notebook: Notebook, page: NotebookPage) -> some View {
        HStack(spacing: 10) {
            Picker("Tool", selection: $tool) {
                ForEach(DrawingTool.allCases) { Label($0.rawValue.capitalized, systemImage: $0.icon).tag($0) }
            }.pickerStyle(.segmented).frame(maxWidth: 420)
            ColorPicker("Ink", selection: $inkColour, supportsOpacity: false).labelsHidden()
            Slider(value: $width, in: 1...12).frame(width: 100)
            Divider().frame(height: 28)
            Button { canvasUndoManager?.undo() } label: { Image(systemName: "arrow.uturn.backward") }
                .disabled(canvasUndoManager?.canUndo != true)
            Button { canvasUndoManager?.redo() } label: { Image(systemName: "arrow.uturn.forward") }
                .disabled(canvasUndoManager?.canRedo != true)
            Menu {
                ForEach(PageTemplate.allCases.filter { $0 != .pdf }) { template in
                    Button(template.title) { store.addPage(to: notebook.id, template: template) }
                }
            } label: { Image(systemName: "doc.badge.plus") }
            Spacer()
            Button { showingAssistant = true } label: { Label("Check Working", systemImage: "sparkles") }
                .buttonStyle(.borderedProminent)
            Menu {
                Button("Rename Notebook") { titleDraft = notebook.title; showingRename = true }
                Button("Export PDF") { exporting = true }
                Button("Delete Page", role: .destructive) { store.deletePage(page.id, in: notebook.id) }
            } label: { Image(systemName: "ellipsis.circle") }
        }
        .padding(.horizontal, 14).padding(.vertical, 8)
        .background(.bar)
    }

    private func pageStrip(notebook: Notebook) -> some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                ForEach(Array(notebook.pages.enumerated()), id: \.element.id) { index, page in
                    Button { store.selectPage(page.id, in: notebook.id) } label: {
                        VStack {
                            RoundedRectangle(cornerRadius: 6).fill(.white).frame(width: 76, height: 100)
                                .overlay(Image(systemName: page.template == .pdf ? "doc.richtext" : "pencil.line").foregroundStyle(.gray))
                                .overlay(RoundedRectangle(cornerRadius: 6).stroke(page.id == notebook.selectedPageID ? .indigo : .clear, lineWidth: 3))
                            Text("\(index + 1)").font(.caption)
                        }
                    }.buttonStyle(.plain)
                }
            }.padding(10)
        }.frame(width: 102).background(.bar)
    }

    private func drawingBinding(pageID: UUID) -> Binding<Data> {
        Binding(
            get: { selectedPage?.drawingData ?? Data() },
            set: { store.updateDrawing($0, pageID: pageID, notebookID: notebookID) }
        )
    }
}
