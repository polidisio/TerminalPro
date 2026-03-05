import SwiftUI

struct TerminalView: View {
    let server: Server
    
    @State private var output: String = ""
    @State private var input: String = ""
    @FocusState private var isInputFocused: Bool
    
    private let cyberBackground = Color(red: 0.05, green: 0.08, blue: 0.12)
    private let terminalGreen = Color(red: 0.0, green: 0.9, blue: 0.4)
    private let cyberAccent = Color(red: 0.0, green: 0.9, blue: 0.7)
    
    var body: some View {
        ZStack {
            cyberBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Terminal output
                ScrollViewReader { proxy in
                    ScrollView {
                        Text(output.isEmpty ? "Connecting to \(server.host)..." : output)
                            .font(.system(size: 14, design: .monospaced))
                            .foregroundStyle(terminalGreen)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .id("bottom")
                    }
                    .onChange(of: output) { _, _ in
                        withAnimation {
                            proxy.scrollTo("bottom", anchor: .bottom)
                        }
                    }
                }
                
                Divider()
                    .background(cyberAccent)
                
                // Input area
                HStack {
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
                }
                .padding()
                .background(cyberBackground)
            }
        }
        .navigationTitle(server.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    disconnect()
                } label: {
                    Text("Disconnect")
                        .foregroundStyle(.red)
                }
            }
        }
        .onAppear {
            simulateConnection()
        }
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
