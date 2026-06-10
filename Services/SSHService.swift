import Foundation

protocol SSHServiceProtocol {
    var connected: Bool { get }
    var outputHandler: ((String) -> Void)? { get set }
    var connectionStateHandler: ((Bool) -> Void)? { get set }
    var errorHandler: ((String) -> Void)? { get set }

    func connect(to server: Server, password: String?, privateKey: String?) async throws
    func sendInput(_ text: String)
    func sendCommand(_ command: String)
    func disconnect()
    func readTerminal() -> String
}

enum SSHError: Error, LocalizedError {
    case notConnected
    case authenticationFailed
    case connectionFailed(String)
    case channelOpenFailed
    case execFailed
    case hostKeyVerificationFailed
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .notConnected: return "Not connected to server"
        case .authenticationFailed: return "Authentication failed. Check username and password."
        case .connectionFailed(let msg): return "Connection failed: \(msg)"
        case .channelOpenFailed: return "Failed to open SSH channel"
        case .execFailed: return "Command execution failed"
        case .hostKeyVerificationFailed: return "Host key verification failed"
        case .unknown(let msg): return msg
        }
    }
}

// MARK: - SSH Service Factory
enum SSHServiceFactory {
    static func create() -> SSHServiceProtocol {
        #if targetEnvironment(simulator)
        return MockSSHService()
        #else
        return CitadelSSHService()
        #endif
    }
}