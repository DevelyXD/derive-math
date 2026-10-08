import SwiftUI

struct MathAssistantView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var serverSettings: ServerSettings
    @State private var working = "2x + 6 = 18\n2x = 12\nx = 6"
    @State private var results: [VerificationResult] = []
    @State private var tutorText = ""
    @State private var errorMessage: String?
    @State private var isWorking = false

    private var steps: [String] {
        working.split(whereSeparator: \.isNewline).map(String.init).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
    }

    var body: some View {
        NavigationStack {
            HStack(alignment: .top, spacing: 20) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Enter one expression or equation per line. You can correct recognition here before checking.")
                        .font(.callout).foregroundStyle(.secondary)
                    TextEditor(text: $working)
                        .font(.system(.title3, design: .monospaced))
                        .padding(8).background(.quaternary, in: RoundedRectangle(cornerRadius: 12))
                    Button { check() } label: { Label("Check Working", systemImage: "checkmark.seal") }
                        .buttonStyle(.borderedProminent).disabled(isWorking || steps.isEmpty)
                }
                VStack(alignment: .leading, spacing: 12) {
                    if results.isEmpty {
                        ContentUnavailableView("No results yet", systemImage: "function", description: Text("Check your typed or recognised working."))
                    } else {
                        List(results) { result in
                            HStack(alignment: .top) {
                                Image(systemName: result.status.symbol).foregroundStyle(colour(result.status))
                                VStack(alignment: .leading) {
                                    Text(result.expression).font(.headline)
                                    Text(result.explanation).font(.caption).foregroundStyle(.secondary)
                                }
                            }
                        }.listStyle(.plain)
                        HStack {
                            tutorButton("Give Hint", action: "hint")
                            tutorButton("Explain Mistake", action: "explain_mistake")
                            tutorButton("Next Step", action: "next_step")
                        }
                    }
                    if !tutorText.isEmpty {
                        ScrollView { Text(tutorText).frame(maxWidth: .infinity, alignment: .leading) }
                            .padding().background(.indigo.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
            .padding().navigationTitle("AI Maths Assistant")
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
            .alert("Assistant Error", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
                Button("OK") { errorMessage = nil }
            } message: { Text(errorMessage ?? "Unknown error") }
        }
    }

    private func check() {
        isWorking = true
        Task {
            do { results = try await ServerClient(settings: serverSettings).verify(steps: steps) }
            catch { errorMessage = "Could not reach the PC server. Your notebook remains saved locally. \(error.localizedDescription)" }
            isWorking = false
        }
    }

    private func tutorButton(_ title: String, action: String) -> some View {
        Button(title) {
            isWorking = true
            Task {
                do {
                    tutorText = try await ServerClient(settings: serverSettings).explain(
                        question: "Review this working", steps: steps, results: results, action: action
                    )
                } catch { errorMessage = error.localizedDescription }
                isWorking = false
            }
        }.buttonStyle(.bordered).disabled(isWorking)
    }

    private func colour(_ status: VerificationStatus) -> Color {
        switch status { case .correct: .green; case .incorrect: .red; case .warning: .yellow }
    }
}
