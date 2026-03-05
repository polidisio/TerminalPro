import Foundation

struct Server: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var host: String
    var port: Int
    var username: String
    var authType: AuthType
    var isDefault: Bool
    
    enum AuthType: String, Codable, CaseIterable {
        case password = "Password"
        case key = "SSH Key"
    }
    
    init(
        id: UUID = UUID(),
        name: String,
        host: String,
        port: Int = 22,
        username: String,
        authType: AuthType = .password,
        isDefault: Bool = false
    ) {
        self.id = id
        self.name = name
        self.host = host
        self.port = port
        self.username = username
        self.authType = authType
        self.isDefault = isDefault
    }
}
