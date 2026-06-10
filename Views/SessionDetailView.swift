import SwiftUI

enum ConnectionStatus: Equatable {
    case disconnected
    case connecting
    case connected
    case error(String)

    var color: Color {
        switch self {
        case .disconnected: return .gray
        case .connecting: return .orange
        case .connected: return Theme.terminalGreenLight
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

struct SessionDetailView: View {
    let server: Server

    @StateObject private var sessionManager = SessionManager.shared
    @StateObject private var terminalViewModel = TerminalViewModel()
    @State private var selectedTab = 0
    @State private var sshService: SSHServiceProtocol?
    @State private var connectionStatus: ConnectionStatus = .disconnected
    @State private var isConnecting = false
    @State private var password: String = ""
    @State private var showCustomKeyboard = false
    @State private var showSavePasswordAlert = false
    @State private var showKeyboardToggle = false

    var body: some View {
        ZStack {
            Theme.cyberBackgroundDark.ignoresSafeArea()

            VStack(spacing: 0) {
                if connectionStatus == .disconnected {
                    passwordPrompt
                } else {
                    connectionStatusBar

                    TabView(selection: $selectedTab) {
                        TerminalTabView(
                            server: server,
                            sshService: sshService,
                            connectionStatus: connectionStatus,
                            showCustomKeyboard: showCustomKeyboard,
                            viewModel: terminalViewModel
                        )
                        .tag(0)

                        SFTPBrowserView(server: server)
                            .tag(1)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                }
            }
        }
        .alert("Save Password?", isPresented: $showSavePasswordAlert) {
            Button("Save") {
                savePasswordToKeychain()
            }
            Button("Not Now", role: .cancel) { }
        } message: {
            Text("Would you like to save the password for future connections?")
        }
        .navigationTitle(server.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                connectionIndicator
            }
            ToolbarItem(placement: .principal) {
                if terminalViewModel.isSearching {
                    SearchBar(viewModel: terminalViewModel)
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 12) {
                    if connectionStatus == .connected && selectedTab == 0 {
                        Button {
                            showCustomKeyboard.toggle()
                        } label: {
                            Image(systemName: showCustomKeyboard ? "keyboard.chevron.compact" : "keyboard")
                                .foregroundStyle(Theme.cyberAccentLight)
                        }

                        Button {
                            terminalViewModel.isSearching.toggle()
                            if !terminalViewModel.isSearching {
                                terminalViewModel.clearSearch()
                            }
                        } label: {
                            Image(systemName: terminalViewModel.isSearching ? "magnifyingglass.circle.fill" : "magnifyingglass")
                                .foregroundStyle(Theme.cyberAccentLight)
                        }
                    }
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

    private var passwordPrompt: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "lock.shield")
                .font(.system(size: 60))
                .foregroundStyle(Theme.cyberAccentLight)

            Text("SSH Connection")
                .font(.title2.bold())
                .foregroundStyle(.white)

            VStack(alignment: .leading, spacing: 8) {
                Text("Server: \(server.username)@\(server.host):\(server.port)")
                    .font(.system(.body, design: .monospaced))
                    .foregroundStyle(.gray)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Theme.cyberBackground)
            .cornerRadius(12)

            SecureField("Password", text: $password)
                .textFieldStyle(.plain)
                .padding()
                .background(Theme.cyberBackground)
                .cornerRadius(12)
                .foregroundStyle(.white)
                .autocapitalization(.none)
                .autocorrectionDisabled()
                .onAppear {
                    loadPasswordFromKeychain()
                }

            Button {
                connect()
            } label: {
                HStack {
                    if isConnecting {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "antenna.radiowaves.left.and.right")
                        Text("Connect")
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Theme.cyberAccentLight)
                .foregroundStyle(.black)
                .cornerRadius(12)
            }
            .disabled(password.isEmpty || isConnecting)

            Spacer()
        }
        .padding()
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
                var service = sessionManager.createSession(for: server)

                // Connect output to viewModel
                let viewModel = self.terminalViewModel
                service.outputHandler = { output in
                    DispatchQueue.main.async {
                        viewModel.appendOutput(output)
                    }
                }

                self.sshService = service

                try await service.connect(to: server, password: password, privateKey: nil)

                await MainActor.run {
                    self.connectionStatus = .connected
                    self.isConnecting = false

                    if !self.passwordAlreadySaved() {
                        self.showSavePasswordAlert = true
                    }
                }
            } catch {
                await MainActor.run {
                    self.connectionStatus = .error(error.localizedDescription)
                    self.isConnecting = false
                }
            }
        }
    }

    private func savePasswordToKeychain() {
        let key = "ssh_password_\(server.id.uuidString)"
        if let data = password.data(using: .utf8) {
            try? KeychainService.shared.save(key: key, data: data)
        }
    }

    private func loadPasswordFromKeychain() {
        let key = "ssh_password_\(server.id.uuidString)"
        if let data = try? KeychainService.shared.load(key: key),
           let savedPassword = String(data: data, encoding: .utf8) {
            password = savedPassword
        }
    }

    private func passwordAlreadySaved() -> Bool {
        let key = "ssh_password_\(server.id.uuidString)"
        if let data = try? KeychainService.shared.load(key: key),
           let savedPassword = String(data: data, encoding: .utf8) {
            return savedPassword == password
        }
        return false
    }

    private func disconnect() {
        sshService?.disconnect()
        connectionStatus = .disconnected
    }
}