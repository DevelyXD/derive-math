import PencilKit
import SwiftUI

enum DrawingTool: String, CaseIterable, Identifiable {
    case pen, highlighter, eraser, lasso
    var id: String { rawValue }
    var icon: String {
        switch self {
        case .pen: "pencil.tip"
        case .highlighter: "highlighter"
        case .eraser: "eraser"
        case .lasso: "lasso"
        }
    }
}

struct DrawingCanvas: UIViewRepresentable {
    @Binding var drawingData: Data
    @Binding var canvasUndoManager: UndoManager?
    var tool: DrawingTool
    var colour: UIColor
    var width: CGFloat

    func makeCoordinator() -> Coordinator { Coordinator(drawingData: $drawingData) }

    func makeUIView(context: Context) -> PKCanvasView {
        let canvas = PKCanvasView()
        canvas.delegate = context.coordinator
        canvas.backgroundColor = .clear
        canvas.isOpaque = false
        canvas.drawingPolicy = .anyInput
        canvas.minimumZoomScale = 0.5
        canvas.maximumZoomScale = 4
        canvas.contentSize = CGSize(width: 1536, height: 2048)
        if let drawing = try? PKDrawing(data: drawingData) { canvas.drawing = drawing }
        DispatchQueue.main.async { canvasUndoManager = canvas.undoManager }
        return canvas
    }

    func updateUIView(_ canvas: PKCanvasView, context: Context) {
        let incoming = (try? PKDrawing(data: drawingData)) ?? PKDrawing()
        if canvas.drawing.dataRepresentation() != drawingData { canvas.drawing = incoming }
        switch tool {
        case .pen:
            canvas.tool = PKInkingTool(.pen, color: colour, width: width)
        case .highlighter:
            canvas.tool = PKInkingTool(.marker, color: colour.withAlphaComponent(0.35), width: width * 4)
        case .eraser:
            canvas.tool = PKEraserTool(.vector)
        case .lasso:
            canvas.tool = PKLassoTool()
        }
        context.coordinator.canvas = canvas
    }

    final class Coordinator: NSObject, PKCanvasViewDelegate {
        @Binding var drawingData: Data
        weak var canvas: PKCanvasView?

        init(drawingData: Binding<Data>) { _drawingData = drawingData }

        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            drawingData = canvasView.drawing.dataRepresentation()
        }
    }
}
