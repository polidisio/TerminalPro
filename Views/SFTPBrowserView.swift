import SwiftUI

struct SFTPBrowserView: View {
    let server: Server
    
    @State private var currentPath: String = "/home/\(server.username)"
    @State private var files: [SFTPFile] = []
    @State private var selectedFile: SFTPFile?
    @State private var isLoading = false
    
    private let cyberBackground = Color(red: 0.05, green: 0.08, blue: 0.12)
    private let cyberAccent = Color(red: 0.0, green: 0.9, blue: 0.7)
    private let terminalGreen = Color(red: 0.0, green: 0.9, blue: 0.4)
    private let cyberSecondary = Color(red: 0.0, green: 0.6, blue: 0.5)
    
    var body: some View {
        ZStack {
            cyberBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                pathBar
                
                if isLoading {
                    loadingView
                } else {
                    fileList
                }
            }
        }
        .navigationTitle("SFTP Browser")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    navigateUp()
                } label: {
                    Image(systemName: "arrow.up.circle")
                        .foregroundStyle(cyberAccent)
                }
                .disabled(currentPath == "/")
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    refreshFiles()
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .foregroundStyle(cyberAccent)
                }
            }
        }
        .onAppear {
            loadFiles()
        }
    }
    
    private var pathBar: some View {
        HStack {
            Image(systemName: "folder.fill")
                .foregroundStyle(cyberAccent)
            
            Text(currentPath)
                .font(.system(size: 14, design: .monospaced))
                .foregroundStyle(.white)
            
            Spacer()
        }
        .padding()
        .background(Color(red: 0.08, green: 0.12, blue: 0.18))
    }
    
    private var loadingView: some View {
        VStack {
            Spacer()
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: cyberAccent))
                .scaleEffect(1.5)
            Text("Loading files...")
                .font(.subheadline)
                .foregroundStyle(.gray)
                .padding(.top, 20)
            Spacer()
        }
    }
    
    private var fileList: some View {
        List {
            ForEach(files) { file in
                FileRow(file: file, accent: cyberAccent, terminalGreen: terminalGreen)
                    .listRowBackground(cyberBackground)
                    .onTapGesture {
                        selectedFile = file
                        if file.isDirectory {
                            navigateToDirectory(file.name)
                        }
                    }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }
    
    private func loadFiles() {
        isLoading = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            files = [
                SFTPFile(name: "Documents", isDirectory: true, size: 4096, permissions: "drwxr-xr-x", modified: "2024-01-15"),
                SFTPFile(name: "Downloads", isDirectory: true, size: 4096, permissions: "drwxr-xr-x", modified: "2024-01-20"),
                SFTPFile(name: "Pictures", isDirectory: true, size: 4096, permissions: "drwxr-xr-x", modified: "2024-01-18"),
                SFTPFile(name: ".bashrc", isDirectory: false, size: 124, permissions: "-rw-r--r--", modified: "2024-01-10"),
                SFTPFile(name: "readme.txt", isDirectory: false, size: 2048, permissions: "-rw-r--r--", modified: "2024-01-12"),
                SFTPFile(name: "project.zip", isDirectory: false, size: 15728640, permissions: "-rw-r--r--", modified: "2024-01-22")
            ]
            isLoading = false
        }
    }
    
    private func refreshFiles() {
        loadFiles()
    }
    
    private func navigateToDirectory(_ name: String) {
        currentPath = currentPath == "/" ? "/\(name)" : "\(currentPath)/\(name)"
        loadFiles()
    }
    
    private func navigateUp() {
        let components = currentPath.split(separator: "/")
        if components.count > 1 {
            currentPath = components.dropLast().joined(separator: "/")
            if currentPath.isEmpty {
                currentPath = "/"
            }
            loadFiles()
        }
    }
}

struct FileRow: View {
    let file: SFTPFile
    let accent: Color
    let terminalGreen: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: file.isDirectory ? "folder.fill" : fileIcon)
                .font(.title2)
                .foregroundStyle(file.isDirectory ? accent : terminalGreen)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(file.name)
                    .font(.system(size: 15, design: .monospaced))
                    .foregroundStyle(.white)
                
                HStack(spacing: 8) {
                    Text(file.permissions)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(.gray)
                    
                    Text(file.modified)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(.gray)
                }
            }
            
            Spacer()
            
            if !file.isDirectory {
                Text(formatSize(file.size))
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(.gray)
            }
        }
        .padding(.vertical, 8)
    }
    
    private var fileIcon: String {
        let ext = file.name.split(separator: ".").last.map(String.init) ?? ""
        switch ext {
        case "txt", "md", "log":
            return "doc.text.fill"
        case "zip", "tar", "gz":
            return "doc.zipper"
        case "png", "jpg", "jpeg", "gif":
            return "photo.fill"
        case "swift", "py", "js", "ts":
            return "chevron.left.forwardslash.chevron.right"
        default:
            return "doc.fill"
        }
    }
    
    private func formatSize(_ bytes: Int) -> String {
        if bytes < 1024 {
            return "\(bytes)B"
        } else if bytes < 1024 * 1024 {
            return "\(bytes / 1024)KB"
        } else {
            return "\(bytes / (1024 * 1024))MB"
        }
    }
}

struct SFTPFile: Identifiable {
    let id = UUID()
    let name: String
    let isDirectory: Bool
    let size: Int
    let permissions: String
    let modified: String
}
