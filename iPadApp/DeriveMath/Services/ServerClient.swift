import Foundation

@MainActor
final class ServerSettings: ObservableObject {
    @Published var host: String { didSet { UserDefaults.standard.set(host, forKey: "serverHost") } }
    @Published var port: String { didSet { UserDefaults.standard.set(port, forKey: "serverPort") } }
    @Published var useHTTPS: Bool { didSet { UserDefaults.standard.set(useHTTPS, forKey: "serverHTTPS") } }
    @Published var token: String { didSet { try? KeychainStore.set(token, account: "pairingToken") } }
    @Published var status: ConnectionStatus = .disconnected

    init() {
        host = UserDefaults.standard.string(forKey: "serverHost") ?? "192.168.1.2"
        port = UserDefaults.standard.string(forKey: "serverPort") ?? "8000"
        useHTTPS = UserDefaults.standard.bool(forKey: "serverHTTPS")
        token = KeychainStore.get(account: "pairingToken")
    }

    var baseURL: URL? { URL(string: "\(useHTTPS ? "https" : "http")://\(host):\(port)") }
}

enum ConnectionStatus: String {
    case disconnected = "Disconnected"
    case connecting = "Processing"
    case connected = "Connected"
    case error = "Error"
}

struct VerifyPayload: Encodable { let steps: [String] }
struct VerifyResponse: Decodable { let results: [VerificationResult] }
struct ExplainPayload: Encodable {
    let question: String
    let working: [String]
    let verification: [VerificationResult]
    let action: String
    let level: String
}
struct TutorResponse: Decodable { let text: String; let model: String }

@MainActor
struct ServerClient {
    let settings: ServerSettings

    func testConnection() async {
        settings.status = .connecting
        guard let url = settings.baseURL?.appendingPathComponent("health") else {
            settings.status = .error
            return
        }
        do {
            var request = URLRequest(url: url)
            request.timeoutInterval = 5
            let (_, response) = try await URLSession.shared.data(for: request)
            settings.status = (response as? HTTPURLResponse)?.statusCode == 200 ? .connected : .error
        } catch {
            settings.status = .disconnected
        }
    }

    func verify(steps: [String]) async throws -> [VerificationResult] {
        let response: VerifyResponse = try await post("api/verify", body: VerifyPayload(steps: steps))
        return response.results
    }

    func explain(question: String, steps: [String], results: [VerificationResult], action: String) async throws -> String {
        let payload = ExplainPayload(
            question: question, working: steps, verification: results, action: action, level: "VCE"
        )
        let response: TutorResponse = try await post("api/explain", body: payload)
        return response.text
    }

    private func post<Request: Encodable, Response: Decodable>(_ path: String, body: Request) async throws -> Response {
        guard let url = settings.baseURL?.appendingPathComponent(path) else { throw URLError(.badURL) }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 90
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(settings.token)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONEncoder().encode(body)
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
            throw URLError(.badServerResponse)
        }
        return try JSONDecoder().decode(Response.self, from: data)
    }
}
