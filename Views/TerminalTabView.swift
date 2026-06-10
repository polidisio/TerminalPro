import SwiftUI

struct TerminalTabView: View {
    let server: Server
    let sshService: SSHServiceProtocol?
    let connectionStatus: ConnectionStatus
    let showCustomKeyboard: Bool
    @ObservedObject var viewModel: TerminalViewModel

    @FocusState private var isInputFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            terminalOutput

            Divider()
                .background(Theme.cyberAccentLight.opacity(0.3))

            if connectionStatus == .connected && showCustomKeyboard {
                TerminalKeyboardView(onKeyPress: handleKeyPress)
                    .padding(.vertical, 8)
                    .background(Theme.cyberBackgroundDark)
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
                Text(viewModel.displayOutput.isEmpty ? "Initializing terminal..." : viewModel.displayOutput)
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundStyle(Theme.terminalGreenLight)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .textSelection(.enabled)
                    .id("bottom")
            }
            .background(Theme.cyberBackgroundDark)
            .onChange(of: viewModel.scrollbackBuffer.count) { _, _ in
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
                .foregroundStyle(Theme.cyberAccentLight)
                .shadow(color: Theme.cyberAccentLight.opacity(0.5), radius: 2)

            TextField("Enter command", text: $viewModel.currentInput)
                .font(.system(size: 14, design: .monospaced))
                .foregroundStyle(.white)
                .focused($isInputFocused)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.go)
                .onSubmit {
                    sendCommand()
                }
                .onChange(of: viewModel.currentInput) { _, _ in
                    viewModel.resetHistoryNavigation()
                }

            Button {
                sendCommand()
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title2)
                    .foregroundStyle(Theme.cyberAccentLight)
            }
            .disabled(viewModel.currentInput.isEmpty || connectionStatus != .connected)
        }
        .padding()
        .background(
            Color(red: 0.04, green: 0.06, blue: 0.1)
                .overlay(
                    Rectangle()
                        .fill(Theme.cyberAccentLight.opacity(0.2))
                        .frame(height: 1),
                    alignment: .top
                )
        )
    }

    private func initializeTerminal() {
        let initialOutput: String
        if let service = sshService {
            // Real SSH connection - let the outputHandler provide the welcome message
            initialOutput = ""
        } else {
            // Mock/simulator - show simulated welcome
            initialOutput = """
            \(server.username)@\(server.host)'s password:
            Last login: \(formattedDate())
            Welcome to Ubuntu 22.04.3 LTS (GNU/Linux 5.15.0-91-generic x86_64)
             * Documentation:  https://help.ubuntu.com
             * Management:     https://landscape.canonical.com
             * Support:        https://ubuntu.com/advantage

            \(server.username)@\(server.host):~$
            """
        }
        viewModel.appendOutput(initialOutput)
    }

    private func handleKeyPress(_ key: String) {
        switch key {
        case "Ctrl":
            break
        case "Tab":
            viewModel.currentInput += "\t"
        case "Esc":
            viewModel.currentInput += "\u{1B}"
        case "↑":
            viewModel.currentInput = viewModel.historyPrevious()
        case "↓":
            viewModel.currentInput = viewModel.historyNext()
        case "→":
            viewModel.currentInput += "\u{1B}[C"
        case "←":
            viewModel.currentInput += "\u{1B}[D"
        case "Enter":
            sendCommand()
        case "⌫":
            if !viewModel.currentInput.isEmpty {
                viewModel.currentInput.removeLast()
            }
        default:
            viewModel.currentInput += key
        }
    }

    private func sendCommand() {
        guard !viewModel.currentInput.isEmpty else { return }

        let command = viewModel.currentInput
        viewModel.addToHistory(command)

        let prompt = "\(server.username)@\(server.host):~$ "
        viewModel.appendLine(command)

        if let service = sshService {
            service.sendCommand(command)
            viewModel.appendLine(prompt)
            viewModel.currentInput = ""
        } else {
            let response = simulateResponse(command)
            viewModel.appendOutput(response + "\n")
            viewModel.appendLine(prompt)
            viewModel.currentInput = ""
        }
    }

    private func simulateResponse(_ cmd: String) -> String {
        let trimmed = cmd.trimmingCharacters(in: .whitespaces).lowercased()
        switch trimmed {
        case "ls", "ls -la", "ls -l":
            return "total 48\ndrwxr-xr-x  5 jose  jose  4096 Mar  5 10:00 .\ndr-xr-x 18 root root  4096 Feb 20 09:00 ..\ndr-xr-x  5 jose  jose  4096 Mar  5 08:00 Desktop\ndrwxr-xr-x  5 jose  jose  4096 Mar  5 07:00 Documents\ndrwxr-xr-x  3 jose  jose  4096 Feb 28 14:00 Downloads\ndrwxr-xr-x  2 jose  jose  4096 Mar  1 11:00 Pictures"
        case "pwd": return "/home/\(server.username)"
        case "whoami": return server.username
        case "hostname": return server.host
        case "date": return formattedDate()
        case "uname -a": return "Linux \(server.host) 5.15.0-91-generic #101-Ubuntu SMP x86_64 GNU/Linux"
        case "clear": viewModel.clearBuffer(); return ""
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