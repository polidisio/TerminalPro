import Foundation

// MARK: - Mock SSH Service for Simulator
class MockSSHService: NSObject, SSHServiceProtocol {
    private var isConnected = false
    private var currentServer: Server?
    private var outputBuffer = ""

    var outputHandler: ((String) -> Void)?
    var connectionStateHandler: ((Bool) -> Void)?
    var errorHandler: ((String) -> Void)?

    var connected: Bool { isConnected }

    override init() {
        super.init()
    }

    func connect(to server: Server, password: String? = nil, privateKey: String? = nil) async throws {
        try await Task.sleep(nanoseconds: 500_000_000)

        currentServer = server
        isConnected = true
        connectionStateHandler?(true)

        outputBuffer = """
        \(server.username)@\(server.host)'s password:
        Last login: \(formattedDate())
        \(server.username)@\(server.host):~$
        """
        outputHandler?(outputBuffer)
    }

    func execute(command: String) async throws -> String {
        guard isConnected else {
            throw SSHError.notConnected
        }

        let trimmed = command.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return "" }
        if trimmed == "exit" { return "logout\nConnection closed." }

        outputBuffer += trimmed + "\n"

        let response = simulateResponse(command)
        outputBuffer += response + "\n"
        outputBuffer += "\(currentServer?.username ?? "user")@\(currentServer?.host ?? "host"):~$ "

        return response
    }

    func readTerminal() -> String {
        return outputBuffer
    }

    func disconnect() {
        isConnected = false
        currentServer = nil
        connectionStateHandler?(false)
        outputBuffer = "Connection closed.\n"
    }

    func sendInput(_ text: String) {
        outputBuffer += text
    }

    func sendCommand(_ command: String) {
        sendInput(command + "\n")
    }

    private func simulateResponse(_ cmd: String) -> String {
        let trimmed = cmd.trimmingCharacters(in: .whitespaces).lowercased()
        switch trimmed {
        case "ls", "ls -la", "ls -l":
            return "total 48\ndrwxr-xr-x  5 jose  jose  4096 Mar  5 10:00 .\ndr-xr-x  18 root root 4096 Feb 20 09:00 ..\ndr-xr-x  5 jose  jose  4096 Mar  5 08:00 Desktop\ndrwxr-xr-x  5 jose  jose  4096 Mar  5 07:00 Documents\ndrwxr-xr-x  3 jose  jose  4096 Feb 28 14:00 Downloads\ndrwxr-xr-x  2 jose  jose  4096 Mar  1 11:00 Pictures"
        case "pwd": return "/home/\(currentServer?.username ?? "user")"
        case "whoami": return currentServer?.username ?? "user"
        case "hostname": return currentServer?.host ?? "localhost"
        case "date": return formattedDate()
        case "uname -a": return "Linux \(currentServer?.host ?? "host") 5.15.0-91-generic #101-Ubuntu SMP x86_64 GNU/Linux"
        case "clear": outputBuffer = ""; return ""
        case "help": return "Available commands: ls, pwd, whoami, hostname, date, uname, clear, exit"
        case "exit": return "logout\nConnection closed."
        default: return "\(cmd): command not found"
        }
    }

    private func formattedDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE MMM d HH:mm:ss zzz yyyy"
        return formatter.string(from: Date())
    }
}