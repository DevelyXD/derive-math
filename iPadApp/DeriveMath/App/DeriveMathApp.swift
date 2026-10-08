import SwiftUI

@main
struct DeriveMathApp: App {
    @StateObject private var store = NotebookStore()
    @StateObject private var serverSettings = ServerSettings()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            AppShell()
                .environmentObject(store)
                .environmentObject(serverSettings)
                .onChange(of: scenePhase) { _, phase in
                    if phase != .active { store.saveNow() }
                }
        }
    }
}
