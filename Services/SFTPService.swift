import Foundation

class SFTPService {
    // Mock SFTP implementation - in production, use NMSSH or similar
    // Note: Real SFTP requires native library integration
    
    private var isConnected = false
    private var currentPath: String = "/"
    
    struct FileItem: Identifiable {
        let id = UUID()
        let name: String
        let isDirectory: Bool
        let size: Int64
        let permissions: String
        let modifiedDate: Date
        
        var icon: String {
            isDirectory ? "folder.fill" : "doc.fill"
        }
    }
    
    func connect(to server: Server) async throws {
        try await Task.sleep(nanoseconds: 1_000_000_000)
        isConnected = true
        currentPath = "/home/\(server.username)"
    }
    
    func listFiles(at path: String) async throws -> [FileItem] {
        guard isConnected else {
            throw SFTPError.notConnected
        }
        
        try await Task.sleep(nanoseconds: 500_000_000)
        
        currentPath = path
        
        // Simulated file listing
        return [
            FileItem(name: "Desktop", isDirectory: true, size: 0, permissions: "drwxr-xr-x", modifiedDate: Date()),
            FileItem(name: "Documents", isDirectory: true, size: 0, permissions: "drwxr-xr-x", modifiedDate: Date()),
            FileItem(name: "Downloads", isDirectory: true, size: 0, permissions: "drwxr-xr-x", modifiedDate: Date()),
            FileItem(name: "readme.txt", isDirectory: false, size: 1024, permissions: "-rw-r--r--", modifiedDate: Date()),
            FileItem(name: "config.json", isDirectory: false, size: 2048, permissions: "-rw-r--r--", modifiedDate: Date()),
        ]
    }
    
    func uploadFile(localPath: String, remotePath: String) async throws {
        guard isConnected else {
            throw SFTPError.notConnected
        }
        
        try await Task.sleep(nanoseconds: 2_000_000_000)
        // Mock upload success
    }
    
    func downloadFile(remotePath: String, localPath: String) async throws {
        guard isConnected else {
            throw SFTPError.notConnected
        }
        
        try await Task.sleep(nanoseconds: 2_000_000_000)
        // Mock download success
    }
    
    func disconnect() {
        isConnected = false
        currentPath = "/"
    }
    
    var connected: Bool {
        isConnected
    }
    
    var currentDirectory: String {
        currentPath
    }
}

enum SFTPError: Error, LocalizedError {
    case notConnected
    case fileNotFound
    case permissionDenied
    case transferFailed
    
    var errorDescription: String? {
        switch self {
        case .notConnected:
            return "Not connected to server"
        case .fileNotFound:
            return "File not found"
        case .permissionDenied:
            return "Permission denied"
        case .transferFailed:
            return "Transfer failed"
        }
    }
}
