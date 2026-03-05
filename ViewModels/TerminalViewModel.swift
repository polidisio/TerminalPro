import Foundation
import Combine

@MainActor
class TerminalViewModel: ObservableObject {
    @Published var scrollbackBuffer: [String] = []
    @Published var commandHistory: [String] = []
    @Published var currentInput: String = ""
    @Published var historyIndex: Int = -1
    @Published var searchQuery: String = ""
    @Published var isSearching: Bool = false
    @Published var searchResults: [Int] = []
    @Published var currentSearchIndex: Int = 0
    
    private let maxScrollbackLines = 10000
    private let maxHistoryItems = 500
    private var historySearchIndex: Int = -1
    
    var displayOutput: String {
        scrollbackBuffer.joined(separator: "\n")
    }
    
    var hasSearchResults: Bool {
        !searchResults.isEmpty
    }
    
    var currentSearchResult: String {
        guard currentSearchIndex >= 0 && currentSearchIndex < searchResults.count else { return "" }
        let lineIndex = searchResults[currentSearchIndex]
        guard lineIndex < scrollbackBuffer.count else { return "" }
        return scrollbackBuffer[lineIndex]
    }
    
    func appendOutput(_ text: String) {
        let lines = text.components(separatedBy: "\n")
        for line in lines {
            scrollbackBuffer.append(line)
            if scrollbackBuffer.count > maxScrollbackLines {
                scrollbackBuffer.removeFirst()
            }
        }
    }
    
    func appendLine(_ line: String) {
        scrollbackBuffer.append(line)
        if scrollbackBuffer.count > maxScrollbackLines {
            scrollbackBuffer.removeFirst()
        }
    }
    
    func clearBuffer() {
        scrollbackBuffer.removeAll()
    }
    
    func addToHistory(_ command: String) {
        guard !command.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        if commandHistory.last != command {
            commandHistory.append(command)
            if commandHistory.count > maxHistoryItems {
                commandHistory.removeFirst()
            }
        }
        historyIndex = -1
    }
    
    func historyPrevious() -> String {
        if commandHistory.isEmpty { return currentInput }
        
        if historyIndex == -1 {
            historyIndex = commandHistory.count - 1
        } else if historyIndex > 0 {
            historyIndex -= 1
        }
        
        return commandHistory[historyIndex]
    }
    
    func historyNext() -> String {
        if historyIndex == -1 { return currentInput }
        
        if historyIndex < commandHistory.count - 1 {
            historyIndex += 1
            return commandHistory[historyIndex]
        } else {
            historyIndex = -1
            return ""
        }
    }
    
    func resetHistoryNavigation() {
        historyIndex = -1
    }
    
    func search(_ query: String) {
        searchQuery = query
        searchResults.removeAll()
        currentSearchIndex = 0
        
        guard !query.isEmpty else { return }
        
        for (index, line) in scrollbackBuffer.enumerated() {
            if line.localizedCaseInsensitiveContains(query) {
                searchResults.append(index)
            }
        }
    }
    
    func nextSearchResult() {
        guard !searchResults.isEmpty else { return }
        currentSearchIndex = (currentSearchIndex + 1) % searchResults.count
    }
    
    func previousSearchResult() {
        guard !searchResults.isEmpty else { return }
        currentSearchIndex = (currentSearchIndex - 1 + searchResults.count) % searchResults.count
    }
    
    func clearSearch() {
        searchQuery = ""
        searchResults = []
        currentSearchIndex = 0
        isSearching = false
    }
}
