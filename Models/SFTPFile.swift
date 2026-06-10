import Foundation

struct SFTPFile: Identifiable, Hashable {
    let id: UUID
    let name: String
    let path: String
    let isDirectory: Bool
    let size: UInt64
    let permissions: String
    let modified: Date
    let isSymlink: Bool

    init(
        name: String,
        path: String = "",
        isDirectory: Bool,
        size: UInt64 = 0,
        permissions: String = "",
        modified: Date = Date(),
        isSymlink: Bool = false
    ) {
        self.id = UUID()
        self.name = name
        self.path = path.isEmpty ? "/\(name)" : path
        self.isDirectory = isDirectory
        self.size = size
        self.permissions = permissions
        self.modified = modified
        self.isSymlink = isSymlink
    }

    init(
        name: String,
        isDirectory: Bool,
        size: Int,
        permissions: String,
        modifiedString: String
    ) {
        self.id = UUID()
        self.name = name
        self.path = "/\(name)"
        self.isDirectory = isDirectory
        self.size = UInt64(size)
        self.permissions = permissions
        self.isSymlink = false

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        self.modified = formatter.date(from: modifiedString) ?? Date()
    }

    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: Int64(size), countStyle: .file)
    }

    var formattedModified: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: modified)
    }

    var icon: String {
        if isSymlink {
            return "link"
        }
        return isDirectory ? "folder.fill" : "doc.fill"
    }
}