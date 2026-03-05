import Foundation

@MainActor
class SessionManager: ObservableObject {
    static let shared = SessionManager()
    
    @Published var sessions: [UUID: SSHService] = [:]
    @Published var activeSessionId: UUID?
    
    private init() {}
    
    func createSession(for server: Server) -> SSHService {
        let service = SSHService()
        let sessionId = server.id
        sessions[sessionId] = service
        activeSessionId = sessionId
        return service
    }
    
    func getSession(id: UUID) -> SSHService? {
        return sessions[id]
    }
    
    func getActiveSession() -> SSHService? {
        guard let id = activeSessionId else { return nil }
        return sessions[id]
    }
    
    func setActiveSession(id: UUID) {
        activeSessionId = id
    }
    
    func closeSession(id: UUID) {
        if let session = sessions[id] {
            session.disconnect()
        }
        sessions.removeValue(forKey: id)
        
        if activeSessionId == id {
            activeSessionId = sessions.keys.first
        }
    }
    
    func closeAllSessions() {
        for (_, session) in sessions {
            session.disconnect()
        }
        sessions.removeAll()
        activeSessionId = nil
    }
    
    var activeSession: SSHService? {
        guard let id = activeSessionId else { return nil }
        return sessions[id]
    }
}
