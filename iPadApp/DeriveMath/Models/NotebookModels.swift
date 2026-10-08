import Foundation

enum PageTemplate: String, Codable, CaseIterable, Identifiable {
    case blank, lined, grid, dotted, pdf
    var id: String { rawValue }
    var title: String { rawValue.capitalized }
}

struct NotebookPage: Identifiable, Codable, Hashable {
    var id = UUID()
    var title: String
    var template: PageTemplate = .blank
    var drawingData = Data()
    var pdfPageIndex: Int?
}

struct Notebook: Identifiable, Codable, Hashable {
    var id = UUID()
    var title: String
    var folderID: UUID?
    var pages = [NotebookPage(title: "Page 1")]
    var currentPageID: UUID?
    var pdfData: Data?
    var createdAt = Date()
    var modifiedAt = Date()

    var selectedPageID: UUID { currentPageID ?? pages.first!.id }
}

struct NotebookFolder: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
    var parentID: UUID?
    var colourHex = "5B6EF5"
}

struct LibraryState: Codable {
    var folders: [NotebookFolder] = []
    var notebooks: [Notebook] = []
}

enum VerificationStatus: String, Codable {
    case correct, incorrect, warning

    var symbol: String {
        switch self {
        case .correct: "checkmark.circle.fill"
        case .incorrect: "xmark.circle.fill"
        case .warning: "questionmark.circle.fill"
        }
    }
}

struct VerificationResult: Codable, Identifiable {
    let index: Int
    let expression: String
    let status: VerificationStatus
    let explanation: String
    var id: Int { index }
}
