import Foundation

class SSHService {
    // Mock SSH implementation - in production, use NMSSH or similar
    // Note: Real SSH requires native library integration
    
    private var isConnected = false
    private var currentServer: Server?
    private var outputBuffer: String = ""
    
    func connect(to server: Server, password: String? = nil, privateKey: String? = nil) async throws {
        // Simulate connection delay
        try await Task.sleep(nanoseconds: 1_500_000_000)
        
        // In a real implementation, this would use NMSSH or similar
        // For now, we simulate a successful connection
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
        guard isConnected else {
            throw SSHError.notConnected
        }
        
        // Simulate command execution delay
        try await Task.sleep(nanoseconds: 300_000_000)
        
        // Simulated responses based on command
        let response = simulateCommandResponse(command)
        outputBuffer += "\n\(command)\n\(response)\n"
        
        if let server = currentServer {
            outputBuffer += "\u{1B}[32m\(server.username)@\(server.host):~$\u{1B}[0m "
        }
        
        return response
    }
    
    func getOutput() -> String {
        return outputBuffer
    }
    
    func clearOutput() {
        outputBuffer = ""
    }
    
    func disconnect() {
        isConnected = false
        currentServer = nil
        outputBuffer = "Connection closed.\n"
    }
    
    var connected: Bool {
        isConnected
    }
    
    private func simulateCommandResponse(_ command: String) -> String {
        let cmd = command.lowercased().trimmingCharacters(in: .whitespaces)
        
        switch cmd {
        case "ls", "ls -la", "ls -l":
            return """
            total 32
            drwxr-xr-x  5 jose  jose  4096 Mar  5 10:00 .
            drwxr-xr-x  1 jose  jose  4096 Mar  5 09:00 ..
            drwxr-xr-x  3 jose  jose  4096 Mar  5 08:00 Desktop
            drwxr-xr-x  5 jose  jose  4096 Mar  5 07:00 Documents
            drwxr-xr-x  2 jose  jose  4096 Mar  5 06:00 Downloads
            """
        case "pwd":
            return "/home/\(currentServer?.username ?? "user")"
        case "whoami":
            return currentServer?.username ?? "user"
        case "hostname":
            return currentServer?.host ?? "server"
        case "date":
            return formattedDate()
        case "uname -a":
            return "Linux server 5.15.0 #1 SMP PREEMPT x86_64 GNU/Linux"
        case "cat /etc/os-release":
            return """
            NAME="Ubuntu"
            VERSION="22.04.3 LTS (Jammy Jellyfish)"
            ID=ubuntu
            """
        case "top", "htop":
            return """
            top - 10:00:00 up 5 days,  1:23,  2 users,  load average: 0.52, 0.48, 0.51
            Tasks: 145 total,   1 running, 144 sleeping,   0 stopped,   0 zombie
            %Cpu(s):  5.2 us,  2.1 sy,  0.0 ni, 92.1 id,  0.0 wa,  0.6 hi,  0.0 si
            MiB Mem :  8192.0 total,  2048.0 free,  3072.0 used,  3072.0 buff/cache
            """
        case "df -h":
            return """
            Filesystem      Size  Used Avail Use% Mounted on
            /dev/sda1       100G   45G   55G  45% /
            /dev/sdb1       500G  200G  300G  40% /data
            """
        case "free -h":
            return """
                          total        used        free      shared  buff/cache   available
            Mem:           8Gi       3.0Gi       2.0Gi       100Mi       3.0Gi       4.5Gi
            Swap:         2Gi          0B       2.0Gi
            """
        case "ps":
            return """
              PID TTY          TIME CMD
                1 ?        00:00:05 systemd
              234 ?        00:00:02 sshd
              456 pts/0    00:00:00 bash
              789 pts/0    00:00:00 top
            """
        case "clear":
            outputBuffer = ""
            return ""
        case "exit", "logout":
            disconnect()
            return "logout\nConnection closed."
        default:
            return "\(cmd): command not found"
        }
    }
    
    private func formattedDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE MMM d HH:mm:ss yyyy"
        return formatter.string(from: Date())
    }
}

enum SSHError: Error, LocalizedError {
    case notConnected
    case authenticationFailed
    case connectionTimeout
    case hostKeyVerificationFailed
    
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
        }
    }
}
