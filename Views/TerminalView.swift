import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct TerminalView: View {
    let server: Server
    
    @State private var output: String = ""
    @State private var input: String = ""
    @FocusState private var isInputFocused: Bool
    @AppStorage("copyPasteMode") private var copyPasteMode: String = "Standard"
    
    @State private var selectedText: String = ""
    @State private var showPasteMenu: Bool = false
    @State private var showCopyToast: Bool = false
    
    private let cyberBackground = Color(red: 0.05, green: 0.08, blue: 0.12)
    private let terminalGreen = Color(red: 0.0, green: 0.9, blue: 0.4)
    private let cyberAccent = Color(red: 0.0, green: 0.9, blue: 0.7)
    
    var body: some View {
        ZStack {
            cyberBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                terminalOutput
                
                Divider()
                    .background(cyberAccent)
                
                inputArea
            }
            
            if showCopyToast {
                VStack {
                    Spacer()
                    Text("Copied!")
                        .font(.caption)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(cyberAccent.opacity(0.9))
                        .cornerRadius(8)
                        .padding(.bottom, 120)
                }
                .transition(.opacity)
            }
        }
        .navigationTitle(server.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 16) {
                    Button {
                        copySelectedText()
                    } label: {
                        Image(systemName: "doc.on.doc")
                            .foregroundStyle(cyberAccent)
                    }
                    .disabled(copyPasteMode == "PuTTY Style")
                    .opacity(copyPasteMode == "Standard" ? 1 : 0.5)
                    
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
            simulateConnection()
        }
    }
    
    private var terminalOutput: some View {
        ScrollViewReader { proxy in
            ScrollView {
                Text(output.isEmpty ? "Connecting to \(server.host)..." : output)
                    .font(.system(size: 14, design: .monospaced))
                    .foregroundStyle(terminalGreen)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .id("bottom")
                    .contextMenu {
                        if copyPasteMode == "PuTTY Style" {
                            Button {
                                pasteFromClipboard()
                            } label: {
                                Label("Paste", systemImage: "doc.on.clipboard")
                            }
                        }
                        Button {
                            copyAllOutput()
                        } label: {
                            Label("Copy All", systemImage: "doc.on.doc")
                        }
                    }
                    .simultaneousGesture(
                        LongPressGesture(minimumDuration: 0.5)
                            .onEnded { _ in
                                if copyPasteMode == "PuTTY Style" {
                                    pasteFromClipboard()
                                }
                            }
                    )
                    .simultaneousGesture(
                        TapGesture()
                            .onEnded {
                                if copyPasteMode == "PuTTY Style" {
                                    selectAllText()
                                }
                            }
                    )
            }
            .onChange(of: output) { newValue in
                withAnimation {
                    proxy.scrollTo("bottom", anchor: .bottom)
                }
            }
        }
    }
    
    private var inputArea: some View {
        HStack(spacing: 12) {
            Text("$ ")
                .font(.system(size: 14, design: .monospaced))
                .foregroundStyle(cyberAccent)
            
            TextField("Enter command", text: $input)
                .font(.system(size: 14, design: .monospaced))
                .foregroundStyle(.white)
                .focused($isInputFocused)
                .textInputAutocapitalization(.never)
                .submitLabel(.go)
                .onSubmit {
                    sendCommand()
                }
                .contextMenu {
                    Button {
                        pasteFromClipboard()
                    } label: {
                        Label("Paste", systemImage: "doc.on.clipboard")
                    }
                }
            
            Button {
                pasteFromClipboard()
            } label: {
                Image(systemName: "doc.on.clipboard")
                    .foregroundStyle(cyberAccent)
            }
            
            Button {
                sendCommand()
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title2)
                    .foregroundStyle(cyberAccent)
            }
            .disabled(input.isEmpty)
        }
        .padding()
        .background(cyberBackground)
    }
    
    private func copySelectedText() {
        if !selectedText.isEmpty {
            UIPasteboard.general.string = selectedText
            showCopyFeedback()
        } else {
            copyAllOutput()
        }
    }
    
    private func copyAllOutput() {
        UIPasteboard.general.string = output
        showCopyFeedback()
    }
    
    private func showCopyFeedback() {
        withAnimation {
            showCopyToast = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation {
                showCopyToast = false
            }
        }
    }
    
    private func pasteFromClipboard() {
        if let clipboardContent = UIPasteboard.general.string {
            input += clipboardContent
            isInputFocused = true
        }
    }
    
    private func selectAllText() {
        selectedText = output
    }
    
    private func simulateConnection() {
        output = """
        \(server.username)@\(server.host)'s password:
        Last login: \(formattedDate())
        Welcome to Ubuntu 22.04.3 LTS
        \(server.username)@\(server.host):~$ 
        """
    }
    
    private func sendCommand() {
        guard !input.isEmpty else { return }
        output += input + "\n\(server.username)@\(server.host):~$ "
        input = ""
        
        // Simulate response
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            output += "command executed successfully\n"
        }
    }
    
    private func disconnect() {
        output += "\n\nConnection closed.\n"
    }
    
    private func formattedDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE MMM d HH:mm:ss yyyy"
        return formatter.string(from: Date())
    }
}
