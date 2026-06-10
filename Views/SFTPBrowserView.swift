import SwiftUI

struct SFTPBrowserView: View {
    let server: Server

    @State private var currentPath: String = "/"
    @State private var files: [SFTPFile] = []
    @State private var selectedFile: SFTPFile?
    @State private var isLoading = false
    @State private var showingFileDetails = false

    var body: some View {
        ZStack {
            Theme.cyberBackground.ignoresSafeArea()

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
                        .foregroundStyle(Theme.cyberAccent)
                }
                .disabled(currentPath == "/")
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    refreshFiles()
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .foregroundStyle(Theme.cyberAccent)
                }
            }
        }
        .onAppear {
            loadFiles()
        }
        .sheet(isPresented: $showingFileDetails) {
            if let file = selectedFile {
                FileDetailsSheet(file: file)
            }
        }
    }

    private var pathBar: some View {
        HStack {
            Image(systemName: "folder.fill")
                .foregroundStyle(Theme.cyberAccent)

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
                .progressViewStyle(CircularProgressViewStyle(tint: Theme.cyberAccent))
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
                FileRow(file: file)
                    .listRowBackground(Theme.cyberBackground)
                    .onTapGesture {
                        selectedFile = file
                        if file.isDirectory {
                            navigateToDirectory(file.name)
                        } else {
                            showingFileDetails = true
                        }
                    }
                    .contextMenu {
                        Button {
                            selectedFile = file
                            showingFileDetails = true
                        } label: {
                            Label("View Details", systemImage: "info.circle")
                        }

                        if !file.isDirectory {
                            Button {
                                // Download action
                            } label: {
                                Label("Download", systemImage: "arrow.down.circle")
                            }

                            Button {
                                // Copy path action
                            } label: {
                                Label("Copy Path", systemImage: "doc.on.doc")
                            }
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
                SFTPFile(name: "Documents", isDirectory: true, size: 4096, permissions: "drwxr-xr-x", modifiedString: "2024-01-15"),
                SFTPFile(name: "Downloads", isDirectory: true, size: 4096, permissions: "drwxr-xr-x", modifiedString: "2024-01-20"),
                SFTPFile(name: "Pictures", isDirectory: true, size: 4096, permissions: "drwxr-xr-x", modifiedString: "2024-01-18"),
                SFTPFile(name: ".bashrc", isDirectory: false, size: 124, permissions: "-rw-r--r--", modifiedString: "2024-01-10"),
                SFTPFile(name: "readme.txt", isDirectory: false, size: 2048, permissions: "-rw-r--r--", modifiedString: "2024-01-12"),
                SFTPFile(name: "project.zip", isDirectory: false, size: 15728640, permissions: "-rw-r--r--", modifiedString: "2024-01-22")
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

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: file.icon)
                .font(.title2)
                .foregroundStyle(file.isDirectory ? Theme.cyberAccent : Theme.terminalGreen)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 4) {
                Text(file.name)
                    .font(.system(size: 15, design: .monospaced))
                    .foregroundStyle(.white)

                HStack(spacing: 8) {
                    Text(file.permissions)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(.gray)

                    Text(file.formattedModified)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(.gray)
                }
            }

            Spacer()

            if !file.isDirectory {
                Text(file.formattedSize)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(.gray)
            }
        }
        .padding(.vertical, 8)
    }
}