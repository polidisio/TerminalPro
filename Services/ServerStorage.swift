import Foundation

class ServerStorage {
    static let shared = ServerStorage()
    
    private let serversKey = "saved_servers"
    
    private init() {}
    
    func loadServers() -> [Server] {
        guard let data = UserDefaults.standard.data(forKey: serversKey) else {
            return []
        }
        
        do {
            let decoder = JSONDecoder()
            return try decoder.decode([Server].self, from: data)
        } catch {
            print("Failed to load servers: \(error)")
            return []
        }
    }
    
    func saveServers(_ servers: [Server]) {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(servers)
            UserDefaults.standard.set(data, forKey: serversKey)
        } catch {
            print("Failed to save servers: \(error)")
        }
    }
    
    func addServer(_ server: Server) {
        var servers = loadServers()
        servers.append(server)
        saveServers(servers)
    }
    
    func deleteServer(id: UUID) {
        var servers = loadServers()
        servers.removeAll { $0.id == id }
        saveServers(servers)
    }
    
    func updateServer(_ server: Server) {
        var servers = loadServers()
        if let index = servers.firstIndex(where: { $0.id == server.id }) {
            servers[index] = server
            saveServers(servers)
        }
    }
}
