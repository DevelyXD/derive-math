import PencilKit
import PDFKit
import SwiftUI
import UniformTypeIdentifiers

struct NotebookPDFDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.pdf] }
    let data: Data

    init(notebook: Notebook) { data = NotebookPDFRenderer.render(notebook) }
    init(configuration: ReadConfiguration) throws { data = configuration.file.regularFileContents ?? Data() }
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper { FileWrapper(regularFileWithContents: data) }
}

enum NotebookPDFRenderer {
    static func render(_ notebook: Notebook) -> Data {
        let pageRect = CGRect(x: 0, y: 0, width: 768, height: 1024)
        return UIGraphicsPDFRenderer(bounds: pageRect).pdfData { renderer in
            for page in notebook.pages {
                renderer.beginPage()
                UIColor.systemBackground.setFill()
                renderer.cgContext.fill(pageRect)
                if page.template == .pdf, let data = notebook.pdfData,
                   let index = page.pdfPageIndex, let pdf = PDFDocument(data: data),
                   let pdfPage = pdf.page(at: index) {
                    renderer.cgContext.saveGState()
                    renderer.cgContext.translateBy(x: 0, y: pageRect.height)
                    renderer.cgContext.scaleBy(x: 1, y: -1)
                    pdfPage.draw(with: .mediaBox, to: renderer.cgContext)
                    renderer.cgContext.restoreGState()
                } else {
                    drawTemplate(page.template, in: renderer.cgContext, rect: pageRect)
                }
                if let drawing = try? PKDrawing(data: page.drawingData) {
                    drawing.image(from: drawing.bounds, scale: 1).draw(in: drawing.bounds)
                }
            }
        }
    }

    private static func drawTemplate(_ template: PageTemplate, in context: CGContext, rect: CGRect) {
        context.setStrokeColor(UIColor.systemGray4.cgColor)
        context.setLineWidth(0.7)
        if template == .lined || template == .grid {
            for y in stride(from: 32.0, through: rect.height, by: 32) {
                context.move(to: CGPoint(x: 0, y: y)); context.addLine(to: CGPoint(x: rect.width, y: y))
            }
        }
        if template == .grid {
            for x in stride(from: 0.0, through: rect.width, by: 32) {
                context.move(to: CGPoint(x: x, y: 0)); context.addLine(to: CGPoint(x: x, y: rect.height))
            }
        }
        context.strokePath()
    }
}
