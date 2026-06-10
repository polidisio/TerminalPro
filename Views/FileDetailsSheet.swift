import SwiftUI

struct FileDetailsSheet: View {
    let file: SFTPFile

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.cyberBackground.ignoresSafeArea()

                List {
                    Section("File Information") {
                        DetailRow(label: "Name", value: file.name)
                        DetailRow(label: "Type", value: file.isDirectory ? "Directory" : "File")
                        DetailRow(label: "Size", value: file.formattedSize)
                        DetailRow(label: "Permissions", value: file.permissions)
                        DetailRow(label: "Modified", value: file.formattedModified)
                    }
                    .listRowBackground(Theme.cyberBackground)
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
                    .foregroundStyle(Theme.cyberAccent)
                }
            }
        }
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
