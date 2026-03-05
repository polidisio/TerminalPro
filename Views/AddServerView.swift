import SwiftUI

struct AddServerView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var servers: [Server]
    
    @State private var name = ""
    @State private var host = ""
    @State private var port = "22"
    @State private var username = ""
    @State private var authType: Server.AuthType = .password
    
    private let cyberBackground = Color(red: 0.05, green: 0.08, blue: 0.12)
    private let cyberAccent = Color(red: 0.0, green: 0.9, blue: 0.7)
    
    var body: some View {
        NavigationStack {
            ZStack {
                cyberBackground.ignoresSafeArea()
                
                Form {
                    Section("Server Details") {
                        TextField("Name", text: $name)
                            .foregroundStyle(.white)
                        TextField("Host", text: $host)
                            .foregroundStyle(.white)
                            .textInputAutocapitalization(.never)
                        TextField("Port", text: $port)
                            .foregroundStyle(.white)
                            .keyboardType(.numberPad)
                        TextField("Username", text: $username)
                            .foregroundStyle(.white)
                            .textInputAutocapitalization(.never)
                    }
                    
                    Section("Authentication") {
                        Picker("Type", selection: $authType) {
                            ForEach(Server.AuthType.allCases, id: \.self) { type in
                                Text(type.rawValue).tag(type)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Add Server")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(.gray)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveServer() }
                        .foregroundStyle(cyberAccent)
                        .disabled(name.isEmpty || host.isEmpty || username.isEmpty)
                }
            }
        }
    }
    
    private func saveServer() {
        let server = Server(
            name: name,
            host: host,
            port: Int(port) ?? 22,
            username: username,
            authType: authType
        )
        servers.append(server)
        dismiss()
    }
}
