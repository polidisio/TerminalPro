import SwiftUI

struct SettingsView: View {
    @AppStorage("fontSize") private var fontSize: Double = 14
    @AppStorage("fontSizePreset") private var fontSizePreset: String = "Medium"
    @AppStorage("showLineNumbers") private var showLineNumbers = true
    @AppStorage("enableBell") private var enableBell = true
    @AppStorage("keepAliveInterval") private var keepAliveInterval = 60
    @AppStorage("keepAliveEnabled") private var keepAliveEnabled = true
    @AppStorage("connectionTimeout") private var connectionTimeout: Int = 30
    @AppStorage("defaultShell") private var defaultShell = "/bin/bash"
    @AppStorage("colorScheme") private var colorScheme = "cyber"
    
    @State private var showingAbout = false
    
    private let cyberBackground = Color(red: 0.05, green: 0.08, blue: 0.12)
    private let cyberAccent = Color(red: 0.0, green: 0.9, blue: 0.7)
    private let terminalGreen = Color(red: 0.0, green: 0.9, blue: 0.4)
    private let cyberSecondary = Color(red: 0.0, green: 0.6, blue: 0.5)
    
    private let fontSizeOptions = ["Small", "Medium", "Large", "Extra Large"]
    
    private func fontSizeValue(for preset: String) -> Double {
        switch preset {
        case "Small": return 12
        case "Medium": return 14
        case "Large": return 18
        case "Extra Large": return 24
        default: return 14
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                cyberBackground.ignoresSafeArea()
                
                List {
                    terminalSection
                    connectionSection
                    appearanceSection
                    aboutSection
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .preferredColorScheme(.dark)
            .sheet(isPresented: $showingAbout) {
                AboutView(cyberAccent: cyberAccent, terminalGreen: terminalGreen)
            }
        }
    }
    
    private var terminalSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                Text("Font Size")
                    .foregroundStyle(.white)
                
                Picker("Font Size", selection: $fontSizePreset) {
                    ForEach(fontSizeOptions, id: \.self) { option in
                        Text(option).tag(option)
                    }
                }
                .pickerStyle(.segmented)
                .onChange(of: fontSizePreset) { newValue in
                    fontSize = fontSizeValue(for: newValue)
                }
                
                HStack {
                    Text("Preview:")
                        .foregroundStyle(.gray)
                    Text("The quick brown fox")
                        .font(.system(size: fontSize, design: .monospaced))
                        .foregroundStyle(terminalGreen)
                }
                .padding(.top, 4)
            }
            .listRowBackground(cyberBackground)
            
            Picker("Default Shell", selection: $defaultShell) {
                Text("/bin/bash").tag("/bin/bash")
                Text("/bin/zsh").tag("/bin/zsh")
                Text("/bin/sh").tag("/bin/sh")
                Text("/usr/bin/fish").tag("/usr/bin/fish")
            }
            .listRowBackground(cyberBackground)
            .foregroundStyle(.white)
            
            Toggle("Show Line Numbers", isOn: $showLineNumbers)
                .listRowBackground(cyberBackground)
                .tint(cyberAccent)
                .foregroundStyle(.white)
            
            Toggle("Enable Bell", isOn: $enableBell)
                .listRowBackground(cyberBackground)
                .tint(cyberAccent)
                .foregroundStyle(.white)
        } header: {
            Text("Terminal")
                .foregroundStyle(cyberSecondary)
        }
    }
    
    private var connectionSection: some View {
        Section {
            Toggle("Enable Keep-Alive Ping", isOn: $keepAliveEnabled)
                .listRowBackground(cyberBackground)
                .tint(cyberAccent)
                .foregroundStyle(.white)
            
            if keepAliveEnabled {
                Picker("Keep-Alive Interval", selection: $keepAliveInterval) {
                    Text("30 seconds").tag(30)
                    Text("60 seconds").tag(60)
                    Text("120 seconds").tag(120)
                    Text("300 seconds").tag(300)
                }
                .listRowBackground(cyberBackground)
                .foregroundStyle(.white)
            }
            
            Picker("Connection Timeout", selection: $connectionTimeout) {
                Text("15 seconds").tag(15)
                Text("30 seconds").tag(30)
                Text("60 seconds").tag(60)
                Text("90 seconds").tag(90)
                Text("120 seconds").tag(120)
            }
            .listRowBackground(cyberBackground)
            .foregroundStyle(.white)
            
            NavigationLink {
                SSHKeyManagementView(cyberAccent: cyberAccent)
            } label: {
                HStack {
                    Text("SSH Keys")
                        .foregroundStyle(.white)
                    Spacer()
                    Text("Manage")
                        .font(.subheadline)
                        .foregroundStyle(.gray)
                }
            }
            .listRowBackground(cyberBackground)
        } header: {
            Text("Connection")
                .foregroundStyle(cyberSecondary)
        }
    }
    
    private var appearanceSection: some View {
        Section {
            Picker("Color Scheme", selection: $colorScheme) {
                Text("Cyber (Cyan/Green)").tag("cyber")
                Text("Matrix (Green/Black)").tag("matrix")
                Text("Neon (Pink/Purple)").tag("neon")
                Text("Monochrome").tag("mono")
            }
            .listRowBackground(cyberBackground)
            .foregroundStyle(.white)
            
            NavigationLink {
                KeyboardSettingsView(cyberAccent: cyberAccent)
            } label: {
                HStack {
                    Text("Keyboard")
                        .foregroundStyle(.white)
                    Spacer()
                    Text("Customize")
                        .font(.subheadline)
                        .foregroundStyle(.gray)
                }
            }
            .listRowBackground(cyberBackground)
        } header: {
            Text("Appearance")
                .foregroundStyle(cyberSecondary)
        }
    }
    
    private var aboutSection: some View {
        Section {
            Button {
                showingAbout = true
            } label: {
                HStack {
                    Text("About TerminalPro")
                        .foregroundStyle(.white)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundStyle(.gray)
                }
            }
            .listRowBackground(cyberBackground)
            
            HStack {
                Text("Version")
                    .foregroundStyle(.white)
                Spacer()
                Text("1.0.0")
                    .foregroundStyle(.gray)
            }
            .listRowBackground(cyberBackground)
        } header: {
            Text("Info")
                .foregroundStyle(cyberSecondary)
        }
    }
}

struct SSHKeyManagementView: View {
    let cyberAccent: Color
    @State private var keys: [SSHKey] = []
    @Environment(\.dismiss) private var dismiss
    
    private let cyberBackground = Color(red: 0.05, green: 0.08, blue: 0.12)
    
    var body: some View {
        ZStack {
            cyberBackground.ignoresSafeArea()
            
            if keys.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "key.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(cyberAccent)
                    
                    Text("No SSH Keys")
                        .font(.title2)
                        .foregroundStyle(.white)
                    
                    Text("Generate an SSH key to connect to servers without entering a password.")
                        .font(.subheadline)
                        .foregroundStyle(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
            } else {
                List {
                    ForEach(keys) { key in
                        SSHKeyRow(key: key, accent: cyberAccent)
                            .listRowBackground(cyberBackground)
                    }
                    .onDelete(perform: deleteKey)
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
        .navigationTitle("SSH Keys")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Generate") {
                    generateKey()
                }
                .foregroundStyle(cyberAccent)
            }
        }
        .onAppear {
            loadKeys()
        }
    }
    
    private func loadKeys() {
        keys = [
            SSHKey(name: "id_rsa", type: "RSA", created: "2024-01-15", fingerprint: "SHA256:abc123..."),
            SSHKey(name: "id_ed25519", type: "ED25519", created: "2024-01-20", fingerprint: "SHA256:def456...")
        ]
    }
    
    private func generateKey() {
        let newKey = SSHKey(name: "new_key", type: "ED25519", created: "2024-01-25", fingerprint: "SHA256:new123...")
        keys.append(newKey)
    }
    
    private func deleteKey(at offsets: IndexSet) {
        keys.remove(atOffsets: offsets)
    }
}

struct SSHKeyRow: View {
    let key: SSHKey
    let accent: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "key.fill")
                    .foregroundStyle(accent)
                
                Text(key.name)
                    .font(.headline)
                    .foregroundStyle(.white)
            }
            
            HStack(spacing: 16) {
                Text(key.type)
                    .font(.caption)
                    .foregroundStyle(.gray)
                
                Text(key.created)
                    .font(.caption)
                    .foregroundStyle(.gray)
            }
            
            Text(key.fingerprint)
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(.gray)
        }
        .padding(.vertical, 8)
    }
}

struct SSHKey: Identifiable {
    let id = UUID()
    let name: String
    let type: String
    let created: String
    let fingerprint: String
}

struct KeyboardSettingsView: View {
    let cyberAccent: Color
    @State private var hapticFeedback = true
    @State private var keyClickSound = false
    @State private var showSuggestions = true
    
    private let cyberBackground = Color(red: 0.05, green: 0.08, blue: 0.12)
    
    var body: some View {
        ZStack {
            cyberBackground.ignoresSafeArea()
            
            List {
                Toggle("Haptic Feedback", isOn: $hapticFeedback)
                    .listRowBackground(cyberBackground)
                    .tint(cyberAccent)
                    .foregroundStyle(.white)
                
                Toggle("Key Click Sound", isOn: $keyClickSound)
                    .listRowBackground(cyberBackground)
                    .tint(cyberAccent)
                    .foregroundStyle(.white)
                
                Toggle("Show Word Suggestions", isOn: $showSuggestions)
                    .listRowBackground(cyberBackground)
                    .tint(cyberAccent)
                    .foregroundStyle(.white)
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Keyboard")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct AboutView: View {
    let cyberAccent: Color
    let terminalGreen: Color
    @Environment(\.dismiss) private var dismiss
    
    private let cyberBackground = Color(red: 0.05, green: 0.08, blue: 0.12)
    
    var body: some View {
        ZStack {
            cyberBackground.ignoresSafeArea()
            
            VStack(spacing: 30) {
                Spacer()
                
                Image(systemName: "terminal.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(cyberAccent)
                
                Text("TerminalPro")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                
                Text("Version 1.0.0")
                    .font(.subheadline)
                    .foregroundStyle(.gray)
                
                VStack(spacing: 10) {
                    Text("A modern SSH/SFTP client with")
                    Text("cyberpunk-inspired interface")
                }
                .font(.body)
                .foregroundStyle(.gray)
                .multilineTextAlignment(.center)
                
                Divider()
                    .background(cyberAccent)
                    .padding(.horizontal, 60)
                
                VStack(spacing: 8) {
                    Text("Built with SwiftUI")
                        .font(.caption)
                        .foregroundStyle(cyberAccent)
                    
                    Text("Powered by Shout SSH")
                        .font(.caption)
                        .foregroundStyle(terminalGreen)
                }
                
                Spacer()
                
                Button("Close") {
                    dismiss()
                }
                .foregroundStyle(cyberAccent)
                .padding(.bottom, 40)
            }
        }
    }
}
