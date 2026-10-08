import SwiftUI

struct ServerSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: ServerSettings

    var body: some View {
        NavigationStack {
            Form {
                Section("Local AI Server") {
                    TextField("PC address", text: $settings.host)
                        .textInputAutocapitalization(.never).autocorrectionDisabled()
                    TextField("Port", text: $settings.port).keyboardType(.numberPad)
                    SecureField("Pairing token", text: $settings.token)
                    Toggle("Use HTTPS", isOn: $settings.useHTTPS)
                    HStack {
                        Circle().fill(statusColour).frame(width: 10, height: 10)
                        Text(settings.status.rawValue)
                        Spacer()
                        Button("Test Connection") { Task { await ServerClient(settings: settings).testConnection() } }
                    }
                }
                Section("Privacy") {
                    Text("Notebooks and PencilKit strokes stay on this iPad. Only math you explicitly check is sent to the configured PC.")
                    Text("Use HTTP only on a trusted home network. Prefer HTTPS with a trusted certificate for long-term use.")
                }
            }
            .navigationTitle("Server Settings")
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
    }

    private var statusColour: Color {
        switch settings.status { case .connected: .green; case .connecting: .yellow; case .error: .red; case .disconnected: .secondary }
    }
}
