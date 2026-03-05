import Foundation
import Shout

@MainActor
class SFTPService: ObservableObject {
    @Published var isConnected = false
    @Published var isConnecting = false
    @Published var currentPath: String = "/"
    @Published var files: [SFTPFile] = []
    @Published var errorMessage: String?
    @Published var transferProgress: Double = 0
    
    private var ssh: SSH?
    private var sftp: SFTP?
    private var currentServer: Server?
    
    private var homePath: String = "/"
    
    func connect(to server: Server, password: String? = nil, privateKey: String? = nil) async throws {
        await MainActor.run {
            isConnecting = true
            errorMessage = nil
        }
        
        do {
            ssh = try SSH(host: server.host, port: server.port)
            
            if let privateKey = privateKey, !privateKey.isEmpty {
                try ssh?.authenticate(username: server.username, privateKey: privateKey)
            } else if let password = password, !password.isEmpty {
                try ssh?.authenticate(username: server.username, password: password)
            } else {
                throw SFTPError.authenticationFailed
            }
            
            sftp = try ssh?.openSFTP()
            currentServer = server
            homePath = try ssh?.execute("echo $HOME").trimmingCharacters(in: .whitespacesAndNewlines()) ?? "/home/\(server.username)"
            currentPath = homePath
            
            await MainActor.run {
                isConnected = true
                isConnecting = false
            }
            
            try await listDirectory(at: currentPath)
        } catch {
            await MainActor.run {
                isConnecting = false
                errorMessage = error.localizedDescription
            }
            throw SFTPError.connectionFailed(error.localizedDescription)
        }
    }
    
    func listDirectory(at path: String) async throws {
        guard let sftp = sftp, isConnected else {
            throw SFTPError.notConnected
        }
        
        do {
            let entries = try sftp.listDirectory(path)
            await MainActor.run {
                files = entries.map { SFTPFile(from: $0, path: path) }
                    .sorted { $0.isDirectory && !$1.isDirectory ? true : $0.name < $1.name }
                currentPath = path
            }
        } catch {
            await MainActor.run {
                errorMessage = "Failed to list directory: \(error.localizedDescription)"
            }
            throw SFTPError.listFailed(error.localizedDescription)
        }
    }
    
    func navigateUp() async {
        guard currentPath != "/" else { return }
        let parentPath = (currentPath as NSString).deletingLastPathComponent
        if parentPath.isEmpty {
            try? await listDirectory(at: "/")
        } else {
            try? await listDirectory(at: parentPath)
        }
    }
    
    func navigateTo(folder: SFTPFile) async {
        guard folder.isDirectory else { return }
        let newPath = folder.path == "/" ? "/\(folder.name)" : "\(folder.path)/\(folder.name)"
        try? await listDirectory(at: newPath)
    }
    
    func navigateToPath(_ path: String) async {
        try? await listDirectory(at: path)
    }
    
    func downloadFile(_ file: SFTPFile, to localURL: URL, completion: @escaping (Bool, Error?) -> Void) {
        guard let sftp = sftp, isConnected else {
            completion(false, SFTPError.notConnected)
            return
        }
        
        Task {
            do {
                let remotePath = file.path == "/" ? "/\(file.name)" : "\(file.path)/\(file.name)"
                try sftp.read(remotePath) { data in
                    do {
                        try data.write(to: localURL)
                        Task { @MainActor in
                            self.transferProgress = 1.0
                        }
                        completion(true, nil)
                    } catch {
                        completion(false, error)
                    }
                }
            } catch {
                completion(false, error)
            }
        }
    }
    
    func uploadFile(from localURL: URL, to remotePath: String, completion: @escaping (Bool, Error?) -> Void) {
        guard let sftp = sftp, isConnected else {
            completion(false, SFTPError.notConnected)
            return
        }
        
        Task {
            do {
                let fileName = localURL.lastPathComponent
                let destinationPath = remotePath == "/" ? "/\(fileName)" : "\(remotePath)/\(fileName)"
                
                let data = try Data(contentsOf: localURL)
                try sftp.write(data, to: destinationPath)
                
                Task { @MainActor in
                    self.transferProgress = 1.0
                }
                
                try await listDirectory(at: currentPath)
                completion(true, nil)
            } catch {
                completion(false, error)
            }
        }
    }
    
    func createDirectory(name: String) async throws {
        guard let sftp = sftp, isConnected else {
            throw SFTPError.notConnected
        }
        
        let newDirPath = currentPath == "/" ? "/\(name)" : "\(currentPath)/\(name)"
        try sftp.createDirectory(at: newDirPath)
        try await listDirectory(at: currentPath)
    }
    
    func deleteFile(_ file: SFTPFile) async throws {
        guard let sftp = sftp, isConnected else {
            throw SFTPError.notConnected
        }
        
        let filePath = file.path == "/" ? "/\(file.name)" : "\(file.path)/\(file.name)"
        
        if file.isDirectory {
            try sftp.remove(filePath)
        } else {
            try sftp.remove(filePath)
        }
        
        try await listDirectory(at: currentPath)
    }
    
    func disconnect() {
        sftp = nil
        ssh = nil
        isConnected = false
        currentPath = "/"
        files = []
        currentServer = nil
    }
}

struct SFTPFile: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let path: String
    let size: UInt64
    let isDirectory: Bool
    let permissions: String
    let modifiedDate: Date?
    
    init(from entry: SFTPEntry, path: String) {
        self.name = entry.name
        self.path = path
        self.size = entry.size
        self.isDirectory = entry.isDirectory
        self.permissions = entry.permissions
        self.modifiedDate = entry.modifiedDate
    }
    
    init(name: String, path: String, size: UInt64, isDirectory: Bool, permissions: String, modifiedDate: Date?) {
        self.name = name
        self.path = path
        self.size = size
        self.isDirectory = isDirectory
        self.permissions = permissions
        self.modifiedDate = modifiedDate
    }
    
    var formattedSize: String {
        if isDirectory {
            return "--"
        }
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(size))
    }
}

enum SFTPError: Error, LocalizedError {
    case notConnected
    case authenticationFailed
    case connectionFailed(String)
    case listFailed(String)
    case downloadFailed(String)
    case uploadFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .notConnected:
            return "Not connected to server"
        case .authenticationFailed:
            return "Authentication failed"
        case .connectionFailed(let message):
            return "Connection failed: \(message)"
        case .listFailed(let message):
            return "Failed to list directory: \(message)"
        case .downloadFailed(let message):
            return "Download failed: \(message)"
        case .uploadFailed(let message):
            return "Upload failed: \(message)"
        }
    }
}
