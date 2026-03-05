import SwiftUI

@main
struct TerminalProApp: App {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
        }
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New Connection") {
                    NotificationCenter.default.post(name: .newConnection, object: nil)
                }
                .keyboardShortcut("n", modifiers: .command)
            }
            
            CommandGroup(after: .sidebar) {
                Button("Toggle Sidebar") {
                    NotificationCenter.default.post(name: .toggleSidebar, object: nil)
                }
                .keyboardShortcut("s", modifiers: [.command, .control])
                
                Divider()
                
                Button("Settings") {
                    NotificationCenter.default.post(name: .showSettings, object: nil)
                }
                .keyboardShortcut(",", modifiers: .command)
            }
            
            CommandGroup(replacing: .help) {
                Button("TerminalPro Help") {
                    NotificationCenter.default.post(name: .showHelp, object: nil)
                }
                .keyboardShortcut("?", modifiers: .command)
            }
        }
    }
}

extension Notification.Name {
    static let newConnection = Notification.Name("newConnection")
    static let toggleSidebar = Notification.Name("toggleSidebar")
    static let showSettings = Notification.Name("showSettings")
    static let showHelp = Notification.Name("showHelp")
}

struct ContentView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    @State private var selectedServer: Server?
    @State private var showingAddServer = false
    @State private var showingSettings = false
    
    private let cyberBackground = Color(red: 0.05, green: 0.08, blue: 0.12)
    
    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            SidebarView(
                selectedServer: $selectedServer,
                showingAddServer: $showingAddServer,
                showingSettings: $showingSettings
            )
            .navigationSplitViewColumnWidth(min: 200, ideal: 250, max: 300)
        } detail: {
            if let server = selectedServer {
                SessionDetailView(server: server)
            } else {
                EmptyDetailView()
            }
        }
        .navigationSplitViewStyle(.balanced)
        .sheet(isPresented: $showingAddServer) {
            AddServerViewWrapper()
        }
        .sheet(isPresented: $showingSettings) {
            SettingsViewWrapper()
        }
        .onReceive(NotificationCenter.default.publisher(for: .newConnection)) { _ in
            showingAddServer = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .toggleSidebar)) { _ in
            withAnimation {
                switch columnVisibility {
                case .all:
                    columnVisibility = .detailOnly
                case .detailOnly:
                    columnVisibility = .all
                default:
                    columnVisibility = .all
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .showSettings)) { _ in
            showingSettings = true
        }
    }
}

struct SidebarView: View {
    @Binding var selectedServer: Server?
    @Binding var showingAddServer: Bool
    @Binding var showingSettings: Bool
    @State private var servers: [Server] = []
    @State private var selectedTab = 0
    
    private let cyberBackground = Color(red: 0.05, green: 0.08, blue: 0.12)
    private let cyberAccent = Color(red: 0.0, green: 0.9, blue: 0.7)
    private let cyberSecondary = Color(red: 0.0, green: 0.6, blue: 0.5)
    
    var body: some View {
        List(selection: $selectedServer) {
            Section {
                ForEach(servers) { server in
                    NavigationLink(value: server) {
                        ServerRow(server: server, accent: cyberAccent)
                    }
                    .listRowBackground(cyberBackground)
                }
                .onDelete(perform: deleteServer)
            } header: {
                HStack {
                    Text("Servers")
                        .font(.caption)
                        .foregroundStyle(cyberSecondary)
                    Spacer()
                }
            }
        }
        .listStyle(.sidebar)
        .scrollContentBackground(.hidden)
        .background(cyberBackground)
        .navigationTitle("TerminalPro")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingAddServer = true
                } label: {
                    Image(systemName: "plus")
                        .foregroundStyle(cyberAccent)
                }
                .keyboardShortcut("n", modifiers: .command)
                .help("New Connection (⌘N)")
            }
            
            ToolbarItem(placement: .secondaryAction) {
                Button {
                    showingSettings = true
                } label: {
                    Image(systemName: "gear")
                        .foregroundStyle(cyberAccent)
                }
                .keyboardShortcut(",", modifiers: .command)
                .help("Settings (⌘,)")
            }
        }
    }
    
    private func deleteServer(at offsets: IndexSet) {
        servers.remove(atOffsets: offsets)
    }
}

struct EmptyDetailView: View {
    private let cyberBackground = Color(red: 0.05, green: 0.08, blue: 0.12)
    private let cyberAccent = Color(red: 0.0, green: 0.9, blue: 0.7)
    private let cyberSecondary = Color(red: 0.0, green: 0.6, blue: 0.5)
    
    var body: some View {
        ZStack {
            cyberBackground.ignoresSafeArea()
            
            VStack(spacing: 20) {
                Image(systemName: "terminal.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(cyberSecondary)
                
                Text("Select a Server")
                    .font(.title2)
                    .foregroundStyle(.white)
                
                Text("Choose a server from the sidebar or create a new connection")
                    .font(.subheadline)
                    .foregroundStyle(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                
                HStack(spacing: 20) {
                    KeyboardShortcutHint(keys: "⌘", description: "New Connection")
                    KeyboardShortcutHint(keys: "⌘,", description: "Settings")
                }
                .padding(.top, 10)
            }
        }
    }
}

struct KeyboardShortcutHint: View {
    let keys: String
    let description: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(keys)
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundStyle(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.3))
                )
            
            Text(description)
                .font(.caption2)
                .foregroundStyle(.gray)
        }
    }
}

struct AddServerViewWrapper: View {
    @Environment(\.dismiss) private var dismiss
    @State private var servers: [Server] = []
    
    var body: some View {
        NavigationStack {
            AddServerView(servers: $servers)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                }
        }
    }
}

struct SettingsViewWrapper: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            SettingsView()
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") {
                            dismiss()
                        }
                    }
                }
        }
    }
}
