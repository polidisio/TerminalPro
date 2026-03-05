import SwiftUI

struct SessionDetailView: View {
    let server: Server
    
    @StateObject private var sessionManager = SessionManager.shared
    @State private var selectedTab = 0
    @State private var sshService: SSHService?
    @State private var connectionStatus: ConnectionStatus = .disconnected
    @State private var isConnecting = false
    
    private let cyberBackground = Color(red: 0.02, green: 0.04, blue: 0.08)
    private let cyberAccent = Color(red: 0.0, green: 0.95, blue: 0.75)
    private let terminalGreen = Color(red: 0.0, green: 0.95, blue: 0.45)
    
    enum ConnectionStatus: Equatable {
        case disconnected
        case connecting
        case connected
        case error(String)
        
        var color: Color {
            switch self {
            case .disconnected: return .gray
            case .connecting: return .orange
            case .connected: return Color(red: 0.0, green: 0.95, blue: 0.45)
            case .error: return .red
            }
        }
        
        var text: String {
            switch self {
            case .disconnected: return "Disconnected"
            case .connecting: return "Connecting..."
            case .connected: return "Connected"
            case .error(let msg): return "Error: \(msg)"
            }
        }
        
        var icon: String {
            switch self {
            case .disconnected: return "circle.fill"
            case .connecting: return "circle.fill"
            case .connected: return "checkmark.circle.fill"
            case .error: return "exclamationmark.circle.fill"
            }
        }
    }
    
    var body: some View {
        ZStack {
            cyberBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                connectionStatusBar
                
                TabView(selection: $selectedTab) {
                    TerminalTabView(server: server, sshService: sshService, connectionStatus: connectionStatus)
                        .tag(0)
                    
                    SFTPBrowserView(server: server)
                        .tag(1)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
        }
        .navigationTitle(server.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                connectionIndicator
            }
            ToolbarItem(placement: .topBarTrailing) {
                if connectionStatus == .connected {
                    Button {
                        disconnect()
                    } label: {
                        Text("Disconnect")
                            .foregroundStyle(.red)
                    }
                }
            }
        }
        .onAppear {
            connect()
        }
    }
    
    private var connectionStatusBar: some View {
        HStack(spacing: 12) {
            Image(systemName: connectionStatus.icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(connectionStatus.color)
            
            Text(connectionStatus.text)
                .font(.system(size: 13, weight: .medium, design: .monospaced))
                .foregroundStyle(connectionStatus.color)
            
            Spacer()
            
            if connectionStatus == .connected {
                Text("\(server.username)@\(server.host)")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(.gray)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 0)
                .fill(Color(red: 0.04, green: 0.06, blue: 0.1))
                .overlay(
                    Rectangle()
                        .fill(connectionStatus.color.opacity(0.5))
                        .frame(height: 1),
                    alignment: .bottom
                )
        )
    }
    
    private var connectionIndicator: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(connectionStatus.color)
                .frame(width: 8, height: 8)
                .shadow(color: connectionStatus.color.opacity(0.8), radius: connectionStatus == .connected ? 4 : 0)
            
            if connectionStatus == .connecting {
                ProgressView()
                    .scaleEffect(0.6)
                    .tint(.orange)
            }
        }
    }
    
    private func connect() {
        connectionStatus = .connecting
        isConnecting = true
        
        Task {
            do {
                let service = sessionManager.createSession(for: server)
                try await service.connect(to: server)
                await MainActor.run {
                    self.sshService = service
                    self.connectionStatus = .connected
                    self.isConnecting = false
                }
            } catch {
                await MainActor.run {
                    self.connectionStatus = .error(error.localizedDescription)
                    self.isConnecting = false
                }
            }
        }
    }
    
    private func disconnect() {
        sshService?.disconnect()
        connectionStatus = .disconnected
    }
}

struct TerminalTabView: View {
    let server: Server
    let sshService: SSHService?
    let connectionStatus: SessionDetailView.ConnectionStatus
    
    @State private var output: String = ""
    @State private var input: String = ""
    @FocusState private var isInputFocused: Bool
    
    private let cyberBackground = Color(red: 0.02, green: 0.04, blue: 0.08)
    private let terminalGreen = Color(red: 0.0, green: 0.95, blue: 0.45)
    private let cyberAccent = Color(red: 0.0, green: 0.95, blue: 0.75)
    private let cyberSecondary = Color(red: 0.0, green: 0.7, blue: 0.6)
    
    var body: some View {
        VStack(spacing: 0) {
            terminalOutput
            
            Divider()
                .background(cyberAccent.opacity(0.3))
            
            if connectionStatus == .connected {
                TerminalKeyboardView(onKeyPress: handleKeyPress)
                    .padding(.vertical, 8)
                    .background(cyberBackground)
            }
            
            inputArea
        }
        .onAppear {
            initializeTerminal()
        }
    }
    
    private var terminalOutput: some View {
        ScrollViewReader { proxy in
            ScrollView {
                Text(output.isEmpty ? "Initializing terminal..." : output)
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundStyle(terminalGreen)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .textSelection(.enabled)
                    .id("bottom")
            }
            .background(cyberBackground)
            .onChange(of: output) { _ in
                withAnimation(.easeOut(duration: 0.1)) {
                    proxy.scrollTo("bottom", anchor: .bottom)
                }
            }
        }
    }
    
    private var inputArea: some View {
        HStack(spacing: 8) {
            Text("$")
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundStyle(cyberAccent)
                .shadow(color: cyberAccent.opacity(0.5), radius: 2)
            
            TextField("Enter command", text: $input)
                .font(.system(size: 14, design: .monospaced))
                .foregroundStyle(.white)
                .focused($isInputFocused)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.go)
                .onSubmit {
                    sendCommand()
                }
            
            Button {
                sendCommand()
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title2)
                    .foregroundStyle(cyberAccent)
            }
            .disabled(input.isEmpty || connectionStatus != .connected)
        }
        .padding()
        .background(
            Color(red: 0.04, green: 0.06, blue: 0.1)
                .overlay(
                    Rectangle()
                        .fill(cyberAccent.opacity(0.2))
                        .frame(height: 1),
                    alignment: .top
                )
        )
    }
    
    private func initializeTerminal() {
        if let service = sshService {
            output = service.getOutput()
        } else {
            output = """
            \(server.username)@\(server.host)'s password:
            Last login: \(formattedDate())
            Welcome to Ubuntu 22.04.3 LTS (GNU/Linux 5.15.0-91-generic x86_64)
             * Documentation:  https://help.ubuntu.com
             * Management:     https://landscape.canonical.com
             * Support:        https://ubuntu.com/advantage
             
            \(server.username)@\(server.host):~$ 
            """
        }
    }
    
    private func handleKeyPress(_ key: String) {
        switch key {
        case "Ctrl":
            break
        case "Tab":
            input += "\t"
        case "Esc":
            input += "\u{1B}"
        case "↑":
            input += "\u{1B}[A"
        case "↓":
            input += "\u{1B}[B"
        case "→":
            input += "\u{1B}[C"
        case "←":
            input += "\u{1B}[D"
        case "Enter":
            sendCommand()
        case "⌫":
            if !input.isEmpty {
                input.removeLast()
            }
        default:
            input += key
        }
    }
    
    private func sendCommand() {
        guard !input.isEmpty else { return }
        
        let prompt = "\(server.username)@\(server.host):~$ "
        output += input + "\n"
        
        Task {
            var response = ""
            if let service = sshService {
                do {
                    response = try await service.execute(command: input)
                } catch {
                    response = "Error: \(error.localizedDescription)"
                }
            } else {
                response = simulateResponse(input)
            }
            
            await MainActor.run {
                output += response + "\n" + prompt
                input = ""
            }
        }
    }
    
    private func simulateResponse(_ cmd: String) -> String {
        let trimmed = cmd.trimmingCharacters(in: .whitespaces).lowercased()
        switch trimmed {
        case "ls", "ls -la", "ls -l":
            return "total 48\ndrwxr-xr-x  5 jose  jose  4096 Mar  5 10:00 .\ndrwxr-xr-x 18 root root 4096 Feb 20 09:00 ..\ndrwxr-xr-x  5 jose  jose  4096 Mar  5 08:00 Desktop\ndrwxr-xr-x  5 jose  jose  4096 Mar  5 07:00 Documents\ndrwxr-xr-x  3 jose  jose  4096 Feb 28 14:00 Downloads\ndrwxr-xr-x  2 jose  jose  4096 Mar  1 11:00 Pictures"
        case "pwd": return "/home/\(server.username)"
        case "whoami": return server.username
        case "hostname": return server.host
        case "date": return formattedDate()
        case "uname -a": return "Linux \(server.host) 5.15.0-91-generic #101-Ubuntu SMP x86_64 GNU/Linux"
        case "clear": output = ""; return ""
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
