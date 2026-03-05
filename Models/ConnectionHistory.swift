import Foundation

struct ConnectionHistory: Identifiable, Codable, Hashable {
    let id: UUID
    let serverId: UUID
    let serverName: String
    let host: String
    let username: String
    let port: Int
    let connectedAt: Date
    var disconnectedAt: Date?
    var wasSuccessful: Bool
    
    init(
        id: UUID = UUID(),
        serverId: UUID,
        serverName: String,
        host: String,
        username: String,
        port: Int,
        connectedAt: Date = Date(),
        disconnectedAt: Date? = nil,
        wasSuccessful: Bool = true
    ) {
        self.id = id
        self.serverId = serverId
        self.serverName = serverName
        self.host = host
        self.username = username
        self.port = port
        self.connectedAt = connectedAt
        self.disconnectedAt = disconnectedAt
        self.wasSuccessful = wasSuccessful
    }
}
