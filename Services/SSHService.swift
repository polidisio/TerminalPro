import Foundation

// Use NMSSH for real SSH on device, mock for simulator
#if targetEnvironment(simulator)
// Mock SSH implementation for simulator
class SSHService {
    private var isConnected = false
    private var currentServer: Server?
    private var outputBuffer: String = ""
    
    func connect(to server: Server, password: String? = nil, privateKey: String? = nil) async throws {
        try await Task.sleep(nanoseconds: 1_500_000_000)
        currentServer = server
        isConnected = true
        outputBuffer = """
        \(server.username)@\(server.host)'s password:
        Last login: \(formattedDate())
        Welcome to Ubuntu 22.04.3 LTS
        \u{1B}[32m\(server.username)@\(server.host):~$\u{1B}[0m 
        """
    }
    
    func execute(command: String) async throws -> String {
        guard isConnected else { throw SSHError.notConnected }
        try await Task.sleep(nanoseconds: 300_000_000)
        
        let response = simulateCommandResponse(command)
        outputBuffer += "\n\(command)\n\(response)\n"
        if let server = currentServer {
            outputBuffer += "\u{1B}[32m\(server.username)@\(server.host):~$ \u{1B}[0m"
        }
        return response
    }
    
    func getOutput() -> String { outputBuffer }
    func clearOutput() { outputBuffer = "" }
    func disconnect() {
        isConnected = false
        currentServer = nil
        outputBuffer = "Connection closed.\n"
    }
    var connected: Bool { isConnected }
    
    private func simulateCommandResponse(_ cmd: String) -> String {
        switch cmd.lowercased().trimmingCharacters(in: .whitespaces) {
        case "ls", "ls -la": return "total 32\ndrwxr-xr-x 5 jose jose 4096 Mar 5 10:00 .\ndrwxr-xr-x 1 jose jose 4096 Mar 5 09:00 ..\ndrwxr-xr-x 3 jose jose 4096 Mar 5 08:00 Desktop\ndrwxr-xr-x 5 jose jose 4096 Mar 5 07:00 Documents"
        case "pwd": return "/home/\(currentServer?.username ?? "user")"
        case "whoami": return currentServer?.username ?? "user"
        case "hostname": return currentServer?.host ?? "server"
        case "date": return formattedDate()
        default: return "\(cmd): command not found"
        }
    }
    
    private func formattedDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE MMM d HH:mm:ss yyyy"
        return formatter.string(from: Date())
    }
}

#else
// Real SSH implementation using NMSSH for device
import NMSSH

class SSHService {
    private var session: NMSSHSession?
    private var isConnected = false
    private var currentServer: Server?
    private var outputBuffer: String = ""
    
    func connect(to server: Server, password: String? = nil, privateKey: String? = nil) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            DispatchQueue.global(qos: .userInitiated).async {
                let newSession = NMSSHSession(host: server.host, port: server.port, andUsername: server.username)
                newSession?.connect()
                
                if newSession?.isConnected == false {
                    continuation.resume(throwing: SSHError.connectionTimeout)
                    return
                }
                
                var authenticated = false
                if let password = password, !password.isEmpty {
                    authenticated = newSession?.authenticate(byPassword: password) ?? false
                } else if let privateKey = privateKey, !privateKey.isEmpty {
                    authenticated = newSession?.authenticateBy(inMemoryPublicKey: nil, privateKey: privateKey, andPassword: nil) ?? false
                } else {
                    authenticated = newSession?.authenticateByKeyboardInteractive() ?? false
                }
                
                if !authenticated {
                    newSession?.disconnect()
                    continuation.resume(throwing: SSHError.authenticationFailed)
                    return
                }
                
                self.session = newSession
                self.isConnected = true
                self.currentServer = server
                self.outputBuffer = "\(server.username)@\(server.host):~$\n"
                continuation.resume()
            }
        }
    }
    
    func execute(command: String) async throws -> String {
        guard let session = session, isConnected else { throw SSHError.notConnected }
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let response = session.channel.execute(command)
                let output = response.output ?? ""
                let error = response.error ?? ""
                self.outputBuffer += "\(command)\n\(output)\n\(error)\n"
                continuation.resume(returning: error.isEmpty ? output : "\(output)\n\(error)")
            }
        }
    }
    
    func getOutput() -> String { outputBuffer }
    func clearOutput() { outputBuffer = "" }
    func disconnect() {
        session?.disconnect()
        isConnected = false
        currentServer = nil
    }
    var connected: Bool { isConnected }
}
#endif

enum SSHError: Error, LocalizedError {
    case notConnected
    case authenticationFailed
    case connectionTimeout
    case hostKeyVerificationFailed
    
    var errorDescription: String? {
        switch self {
        case .notConnected: return "Not connected to server"
        case .authenticationFailed: return "Authentication failed"
        case .connectionTimeout: return "Connection timed out"
        case .hostKeyVerificationFailed: return "Host key verification failed"
        }
    }
}
