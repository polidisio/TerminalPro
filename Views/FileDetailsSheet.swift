import SwiftUI

struct FileDetailsSheet: View {
    let file: SFTPFile
    let cyberAccent: Color
    let terminalGreen: Color
    let cyberBackground: Color
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                cyberBackground.ignoresSafeArea()
                
                List {
                    Section("File Information") {
                        DetailRow(label: "Name", value: file.name)
                        DetailRow(label: "Type", value: file.isDirectory ? "Directory" : "File")
                        DetailRow(label: "Size", value: formatSize(Int64(file.size)))
                        DetailRow(label: "Permissions", value: file.permissions)
                        DetailRow(label: "Modified", value: file.modified)
                    }
                    .listRowBackground(cyberBackground)
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("File Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(cyberAccent)
                }
            }
        }
    }
    
    private func formatSize(_ size: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: size)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(.gray)
            Spacer()
            Text(value)
                .foregroundStyle(.white)
        }
    }
}
