import Foundation
import Shout

@MainActor
class SSHService: ObservableObject {
    @Published var isConnected = false
    @Published var isConnecting = false
    @Published var output: String = ""
    @Published var errorMessage: String?
    
    private var ssh: SSH?
    private var currentServer: Server?
    private var shell: Shell?
    
    private let terminalFormatter = TerminalFormatter()
    
    func connect(to server: Server, password: String? = nil, privateKey: String? = nil) async throws {
        await MainActor.run {
            isConnecting = true
            errorMessage = nil
            output = "Connecting to \(server.host)...\n"
        }
        
        do {
            ssh = try SSH(host: server.host, port: server.port)
            
            if let privateKey = privateKey, !privateKey.isEmpty {
                try ssh?.authenticate(username: server.username, privateKey: privateKey)
            } else if let password = password, !password.isEmpty {
                try ssh?.authenticate(username: server.username, password: password)
            } else {
                throw SSHError.authenticationFailed
            }
            
            currentServer = server
            await MainActor.run {
                isConnected = true
                isConnecting = false
                output += "Connected to \(server.host)\n"
                output += "\(server.username)@\(server.host):~$ "
            }
        } catch {
            await MainActor.run {
                isConnecting = false
                errorMessage = error.localizedDescription
                output += "Connection failed: \(error.localizedDescription)\n"
            }
            throw SSHError.connectionFailed(error.localizedDescription)
        }
    }
    
    func execute(command: String) async throws -> String {
        guard let ssh = ssh, isConnected else {
            throw SSHError.notConnected
        }
        
        await MainActor.run {
            output += command + "\n"
        }
        
        do {
            let result = try ssh.execute(command)
            await MainActor.run {
                output += result
                if let server = currentServer {
                    output += "\n\(server.username)@\(server.host):~$ "
                }
            }
            return result
        } catch {
            await MainActor.run {
                output += "Error: \(error.localizedDescription)\n"
                if let server = currentServer {
                    output += "\(server.username)@\(server.host):~$ "
                }
            }
            throw SSHError.executionFailed(error.localizedDescription)
        }
    }
    
    func executeStreaming(command: String, onOutput: @escaping (String) -> Void) async throws {
        guard let ssh = ssh, isConnected else {
            throw SSHError.notConnected
        }
        
        await MainActor.run {
            output += command + "\n"
        }
        
        _ = try await ssh.executeStreaming(command, onOut: { line in
            Task { @MainActor in
                onOutput(line)
            }
        }, onErr: { line in
            Task { @MainActor in
                onOutput("[stderr] \(line)")
            }
        })
        
        await MainActor.run {
            if let server = currentServer {
                output += "\n\(server.username)@\(server.host):~$ "
            }
        }
    }
    
    func openShell() async throws {
        guard let ssh = ssh, isConnected else {
            throw SSHError.notConnected
        }
        
        shell = try ssh.executeShell(
            type: ShellType.xterm,
            rows: 24,
            cols: 80,
            onOut: { [weak self] data in
                Task { @MainActor in
                    let formatted = self?.terminalFormatter.format(data) ?? data
                    self?.output += formatted
                }
            },
            onErr: { [weak self] data in
                Task { @MainActor in
                    let formatted = self?.terminalFormatter.format(data) ?? data
                    self?.output += "[stderr] \(formatted)"
                }
            }
        )
    }
    
    func writeToShell(_ data: String) {
        shell?.write(data)
    }
    
    func resizeShell(rows: Int, cols: Int) {
        shell?.resize(rows: rows, cols: cols)
    }
    
    func disconnect() {
        shell = nil
        ssh = nil
        isConnected = false
        currentServer = nil
        
        output += "\n\nConnection closed.\n"
    }
    
    func clearOutput() {
        output = ""
    }
}

class TerminalFormatter {
    private var ansiColors: [String: String] = [
        "30": "#000000",
        "31": "#FF0000",
        "32": "#00FF00",
        "33": "#FFFF00",
        "34": "#0000FF",
        "35": "#FF00FF",
        "36": "#00FFFF",
        "37": "#FFFFFF",
        "90": "#808080",
        "91": "#FF8080",
        "92": "#80FF80",
        "93": "#FFFF80",
        "94": "#8080FF",
        "95": "#FF80FF",
        "96": "#80FFFF",
        "97": "#FFFFFF"
    ]
    
    func format(_ data: Data) -> String {
        guard let string = String(data: data, encoding: .utf8) else {
            return String(data: data, encoding: .ascii) ?? ""
        }
        return format(string)
    }
    
    func format(_ string: String) -> String {
        var result = string
        let ansiPattern = "\u{1B}\\[[0-9;]*m"
        
        if let regex = try? NSRegularExpression(pattern: ansiPattern, options: []) {
            result = regex.stringByReplacingMatches(
                in: result,
                options: [],
                range: NSRange(result.startIndex..., in: result),
                withTemplate: ""
            )
        }
        
        return result
    }
}

enum SSHError: Error, LocalizedError {
    case notConnected
    case authenticationFailed
    case connectionTimeout
    case hostKeyVerificationFailed
    case connectionFailed(String)
    case executionFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .notConnected:
            return "Not connected to server"
        case .authenticationFailed:
            return "Authentication failed"
        case .connectionTimeout:
            return "Connection timed out"
        case .hostKeyVerificationFailed:
            return "Host key verification failed"
        case .connectionFailed(let message):
            return "Connection failed: \(message)"
        case .executionFailed(let message):
            return "Execution failed: \(message)"
        }
    }
}
