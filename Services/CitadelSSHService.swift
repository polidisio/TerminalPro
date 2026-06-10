import Foundation
import Citadel
import NIO

class CitadelSSHService: NSObject, SSHServiceProtocol {
    private var client: SSHClient?
    private var isConnected = false
    private var currentServer: Server?

    var outputHandler: ((String) -> Void)?
    var connectionStateHandler: ((Bool) -> Void)?
    var errorHandler: ((String) -> Void)?

    var connected: Bool { isConnected }

    override init() {
        super.init()
    }

    func connect(to server: Server, password: String?, privateKey: String?) async throws {
        currentServer = server

        let authMethod: SSHAuthenticationMethod
        if let password = password, !password.isEmpty {
            authMethod = .passwordBased(username: server.username, password: password)
        } else {
            authMethod = .passwordBased(username: server.username, password: "")
        }

        let hostKeyValidator = SSHHostKeyValidator.acceptAnything()

        let settings = SSHClientSettings(
            host: server.host,
            port: server.port,
            authenticationMethod: { authMethod },
            hostKeyValidator: hostKeyValidator
        )

        do {
            client = try await SSHClient.connect(to: settings)
            isConnected = true
            connectionStateHandler?(true)
            outputHandler?("Connected to \(server.host):\(server.port)\n")

            // Small delay for connection stability
            try await Task.sleep(nanoseconds: 200_000_000)

        } catch {
            isConnected = false
            connectionStateHandler?(false)
            outputHandler?("Connection failed: \(error.localizedDescription)\n")
            throw SSHError.connectionFailed(error.localizedDescription)
        }
    }

    func sendInput(_ text: String) {
        guard let client = client, isConnected else {
            outputHandler?("Not connected\n")
            return
        }

        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return }

        Task {
            do {
                let result = try await client.executeCommand(trimmed)
                let output = String(bytes: result.readableBytesView, encoding: .utf8) ?? ""

                await MainActor.run {
                    if !output.isEmpty {
                        self.outputHandler?(output)
                    }
                }
            } catch {
                await MainActor.run {
                    self.outputHandler?("Error: \(error.localizedDescription)\n")
                }
            }
        }
    }

    func sendCommand(_ command: String) {
        sendInput(command)
    }

    func disconnect() {
        client = nil
        isConnected = false
        currentServer = nil
        connectionStateHandler?(false)
        outputHandler?("Connection closed.\n")
    }

    func readTerminal() -> String {
        return ""
    }
}