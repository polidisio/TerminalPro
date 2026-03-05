import Foundation

// Use NMSSH for real SFTP on device, mock for simulator
#if targetEnvironment(simulator)
// Mock SFTP implementation for simulator
class SFTPService {
    private var isConnected = false
    private var currentPath: String = "/"
    
    struct FileItem: Identifiable {
        let id = UUID()
        let name: String
        let isDirectory: Bool
        let size: Int64
        let permissions: String
        let modifiedDate: Date
        var icon: String { isDirectory ? "folder.fill" : "doc.fill" }
    }
    
    func connect(to server: Server) async throws {
        try await Task.sleep(nanoseconds: 1_000_000_000)
        isConnected = true
        currentPath = "/home/\(server.username)"
    }
    
    func listFiles(at path: String) async throws -> [FileItem] {
        guard isConnected else { throw SFTPError.notConnected }
        try await Task.sleep(nanoseconds: 500_000_000)
        currentPath = path
        return [
            FileItem(name: "Desktop", isDirectory: true, size: 0, permissions: "drwxr-xr-x", modifiedDate: Date()),
            FileItem(name: "Documents", isDirectory: true, size: 0, permissions: "drwxr-xr-x", modifiedDate: Date()),
            FileItem(name: "Downloads", isDirectory: true, size: 0, permissions: "drwxr-xr-x", modifiedDate: Date()),
            FileItem(name: "readme.txt", isDirectory: false, size: 1024, permissions: "-rw-r--r--", modifiedDate: Date()),
        ]
    }
    
    func uploadFile(localPath: String, remotePath: String) async throws {
        guard isConnected else { throw SFTPError.notConnected }
        try await Task.sleep(nanoseconds: 2_000_000_000)
    }
    
    func downloadFile(remotePath: String, localPath: String) async throws {
        guard isConnected else { throw SFTPError.notConnected }
        try await Task.sleep(nanoseconds: 2_000_000_000)
    }
    
    func disconnect() { isConnected = false; currentPath = "/" }
    var connected: Bool { isConnected }
    var currentDirectory: String { currentPath }
}

#else
// Real SFTP implementation using NMSSH for device
import NMSSH

class SFTPService {
    private var session: NMSSHSession?
    private var sftp: NMSFTP?
    private var isConnected = false
    private var currentPath: String = "/"
    
    struct FileItem: Identifiable {
        let id = UUID()
        let name: String
        let isDirectory: Bool
        let size: Int64
        let permissions: String
        let modifiedDate: Date
        var icon: String { isDirectory ? "folder.fill" : "doc.fill" }
    }
    
    func connect(to server: Server) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            DispatchQueue.global(qos: .userInitiated).async {
                let newSession = NMSSHSession(host: server.host, port: server.port, andUsername: server.username)
                newSession?.connect()
                
                if newSession?.isConnected == false {
                    continuation.resume(throwing: SFTPError.notConnected)
                    return
                }
                
                newSession?.authenticate(byPassword: "")
                let newSftp = NMSFTP(session: newSession!)
                newSftp.connect()
                
                self.session = newSession
                self.sftp = newSftp
                self.isConnected = true
                self.currentPath = "/home/\(server.username)"
                continuation.resume()
            }
        }
    }
    
    func listFiles(at path: String) async throws -> [FileItem] {
        guard let sftp = sftp, isConnected else { throw SFTPError.notConnected }
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                guard let contents = sftp.contentsOfDirectory(atPath: path) as? [NMSFTPFile] else {
                    continuation.resume(returning: [])
                    return
                }
                let files = contents.map { file in
                    FileItem(name: file.filename, isDirectory: file.isDirectory,
                             size: Int64(file.fileSize), permissions: file.permissions ?? "-",
                             modifiedDate: file.modificationDate ?? Date())
                }
                self.currentPath = path
                continuation.resume(returning: files)
            }
        }
    }
    
    func uploadFile(localPath: String, remotePath: String) async throws {
        guard let sftp = sftp, isConnected else { throw SFTPError.notConnected }
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            DispatchQueue.global(qos: .userInitiated).async {
                let success = sftp.writeFile(atPath: localPath, toFileAtPath: remotePath)
                success ? continuation.resume() : continuation.resume(throwing: SFTPError.transferFailed)
            }
        }
    }
    
    func downloadFile(remotePath: String, localPath: String) async throws {
        guard let sftp = sftp, isConnected else { throw SFTPError.notConnected }
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            DispatchQueue.global(qos: .userInitiated).async {
                let success = sftp.contents(atPath: remotePath, toFileAtPath: localPath)
                success ? continuation.resume() : continuation.resume(throwing: SFTPError.transferFailed)
            }
        }
    }
    
    func disconnect() { sftp?.disconnect(); session?.disconnect(); isConnected = false; currentPath = "/" }
    var connected: Bool { isConnected }
    var currentDirectory: String { currentPath }
}
#endif

enum SFTPError: Error, LocalizedError {
    case notConnected
    case fileNotFound
    case permissionDenied
    case transferFailed
    
    var errorDescription: String? {
        switch self {
        case .notConnected: return "Not connected to server"
        case .fileNotFound: return "File not found"
        case .permissionDenied: return "Permission denied"
        case .transferFailed: return "Transfer failed"
        }
    }
}
