import PDFKit
import SwiftUI

struct PageBackground: View {
    let template: PageTemplate
    let pdfData: Data?
    let pdfPageIndex: Int?

    var body: some View {
        ZStack {
            Color(uiColor: .systemBackground)
            if template == .pdf, let pdfData, let pdfPageIndex {
                PDFPageView(data: pdfData, pageIndex: pdfPageIndex)
            } else {
                GeometryReader { proxy in
                    Canvas { context, size in
                        drawTemplate(context: &context, size: size)
                    }
                }
            }
        }
    }

    private func drawTemplate(context: inout GraphicsContext, size: CGSize) {
        let colour = Color.secondary.opacity(0.18)
        var path = Path()
        switch template {
        case .lined:
            stride(from: 36.0, through: size.height, by: 32).forEach {
                path.move(to: CGPoint(x: 0, y: $0)); path.addLine(to: CGPoint(x: size.width, y: $0))
            }
        case .grid:
            stride(from: 0.0, through: size.width, by: 28).forEach {
                path.move(to: CGPoint(x: $0, y: 0)); path.addLine(to: CGPoint(x: $0, y: size.height))
            }
            stride(from: 0.0, through: size.height, by: 28).forEach {
                path.move(to: CGPoint(x: 0, y: $0)); path.addLine(to: CGPoint(x: size.width, y: $0))
            }
        case .dotted:
            for x in stride(from: 14.0, through: size.width, by: 28) {
                for y in stride(from: 14.0, through: size.height, by: 28) {
                    context.fill(Path(ellipseIn: CGRect(x: x, y: y, width: 1.6, height: 1.6)), with: .color(colour))
                }
            }
        default: break
        }
        context.stroke(path, with: .color(colour), lineWidth: 0.7)
    }
}

private struct PDFPageView: UIViewRepresentable {
    let data: Data
    let pageIndex: Int

    func makeUIView(context: Context) -> PDFView {
        let view = PDFView()
        view.autoScales = true
        view.isUserInteractionEnabled = false
        view.backgroundColor = .clear
        return view
    }

    func updateUIView(_ view: PDFView, context: Context) {
        guard let source = PDFDocument(data: data),
              let page = source.page(at: pageIndex) else { return }
        let singlePage = PDFDocument()
        singlePage.insert(page, at: 0)
        view.document = singlePage
    }
}
