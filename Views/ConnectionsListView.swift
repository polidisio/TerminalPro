import SwiftUI

struct ConnectionsListView: View {
    @State private var servers: [Server] = []
    @State private var showingAddServer = false
    
    // Cyber theme colors
    private let cyberBackground = Color(red: 0.05, green: 0.08, blue: 0.12)
    private let cyberAccent = Color(red: 0.0, green: 0.9, blue: 0.7) // Cyan/Teal
    private let cyberSecondary = Color(red: 0.0, green: 0.6, blue: 0.5)
    
    var body: some View {
        NavigationStack {
            ZStack {
                cyberBackground.ignoresSafeArea()
                
                if servers.isEmpty {
                    emptyState
                } else {
                    serversList
                }
            }
            .navigationTitle("Servers")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddServer = true
                    } label: {
                        Image(systemName: "plus")
                            .foregroundStyle(cyberAccent)
                    }
                }
            }
            .sheet(isPresented: $showingAddServer) {
                AddServerView(servers: $servers)
            }
        }
        .preferredColorScheme(.dark)
    }
    
    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "server.rack")
                .font(.system(size: 60))
                .foregroundStyle(cyberSecondary)
            
            Text("No Servers")
                .font(.title2)
                .foregroundStyle(.white)
            
            Text("Add your first server to get started")
                .font(.subheadline)
                .foregroundStyle(.gray)
            
            Button {
                showingAddServer = true
            } label: {
                Text("Add Server")
                    .font(.headline)
                    .foregroundStyle(cyberBackground)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 12)
                    .background(cyberAccent)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
    }
    
    private var serversList: some View {
        List {
            ForEach(servers) { server in
                NavigationLink {
                    TerminalView(server: server)
                } label: {
                    ServerRow(server: server, accent: cyberAccent)
                }
                .listRowBackground(cyberBackground)
            }
            .onDelete(perform: deleteServer)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }
    
    private func deleteServer(at offsets: IndexSet) {
        servers.remove(atOffsets: offsets)
    }
}

struct ServerRow: View {
    let server: Server
    let accent: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "server.rack")
                .font(.title2)
                .foregroundStyle(accent)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(server.name)
                    .font(.headline)
                    .foregroundStyle(.white)
                
                Text("\(server.username)@\(server.host):\(server.port)")
                    .font(.caption)
                    .foregroundStyle(.gray)
            }
            
            Spacer()
            
            Circle()
                .fill(Color.green)
                .frame(width: 8, height: 8)
        }
        .padding(.vertical, 8)
    }
}
