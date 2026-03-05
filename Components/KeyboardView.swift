import SwiftUI

struct TerminalKeyboardView: View {
    let onKeyPress: (String) -> Void
    
    private let keys1 = ["q", "w", "e", "r", "t", "y", "u", "i", "o", "p"]
    private let keys2 = ["a", "s", "d", "f", "g", "h", "j", "k", "l"]
    private let keys3 = ["z", "x", "c", "v", "b", "n", "m"]
    
    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 6) {
                ForEach(keys1, id: \.self) { key in
                    KeyButton(label: key) { onKeyPress(key) }
                }
            }
            
            HStack(spacing: 6) {
                ForEach(keys2, id: \.self) { key in
                    KeyButton(label: key) { onKeyPress(key) }
                }
            }
            
            HStack(spacing: 6) {
                Button {
                    onKeyPress(" ")
                } label: {
                    Text("space")
                        .font(.caption)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.gray.opacity(0.3))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 4)
    }
}

struct KeyButton: View {
    let label: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 18, weight: .medium, design: .monospaced))
                .frame(width: 32, height: 44)
                .background(Color.gray.opacity(0.3))
                .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(.plain)
    }
}
