import Foundation

class ConnectionHistoryStorage {
    static let shared = ConnectionHistoryStorage()
    
    private let historyKey = "connection_history"
    private let maxHistoryCount = 50
    
    private init() {}
    
    func loadHistory() -> [ConnectionHistory] {
        guard let data = UserDefaults.standard.data(forKey: historyKey) else {
            return []
        }
        
        do {
            let decoder = JSONDecoder()
            return try decoder.decode([ConnectionHistory].self, from: data)
        } catch {
            print("Failed to load connection history: \(error)")
            return []
        }
    }
    
    func saveHistory(_ history: [ConnectionHistory]) {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(history)
            UserDefaults.standard.set(data, forKey: historyKey)
        } catch {
            print("Failed to save connection history: \(error)")
        }
    }
    
    func addConnection(_ entry: ConnectionHistory) {
        var history = loadHistory()
        history.insert(entry, at: 0)
        
        if history.count > maxHistoryCount {
            history = Array(history.prefix(maxHistoryCount))
        }
        
        saveHistory(history)
    }
    
    func updateDisconnection(id: UUID, wasSuccessful: Bool = true) {
        var history = loadHistory()
        if let index = history.firstIndex(where: { $0.id == id }) {
            history[index].disconnectedAt = Date()
            history[index].wasSuccessful = wasSuccessful
            saveHistory(history)
        }
    }
    
    func clearHistory() {
        saveHistory([])
    }
    
    func deleteEntry(id: UUID) {
        var history = loadHistory()
        history.removeAll { $0.id == id }
        saveHistory(history)
    }
}
