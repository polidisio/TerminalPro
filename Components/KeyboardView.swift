import SwiftUI

struct TerminalKeyboardView: View {
    let onKeyPress: (String) -> Void

    private let keys1 = ["q", "w", "e", "r", "t", "y", "u", "i", "o", "p"]
    private let keys2 = ["a", "s", "d", "f", "g", "h", "j", "k", "l"]
    private let keys3 = ["z", "x", "c", "v", "b", "n", "m"]

    var body: some View {
        VStack(spacing: 6) {
            specialKeysRow

            keysRow(keys: keys1)
            keysRow(keys: keys2)
            keysRow(keys: keys3)

            bottomRow
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 8)
        .frame(height: 180)
        .background(Theme.keyboardBackground)
    }

    private func keysRow(keys: [String]) -> some View {
        HStack(spacing: 4) {
            ForEach(keys, id: \.self) { key in
                KeyButton(label: key) {
                    onKeyPress(key)
                }
            }
        }
    }

    private var specialKeysRow: some View {
        HStack(spacing: 4) {
            SpecialKeyButton(label: "Ctrl") { onKeyPress("Ctrl") }
            SpecialKeyButton(label: "Tab") { onKeyPress("Tab") }
            SpecialKeyButton(label: "Esc") { onKeyPress("Esc") }

            Spacer()

            ArrowKeysView(onKeyPress: onKeyPress)

            Spacer()

            SpecialKeyButton(label: "Enter") { onKeyPress("Enter") }
        }
    }

    private var bottomRow: some View {
        HStack(spacing: 4) {
            SpecialKeyButton(label: "Alt") { onKeyPress("Alt") }

            ForEach(["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "-", "="], id: \.self) { key in
                KeyButton(label: key) { onKeyPress(key) }
            }

            SpecialKeyButton(label: "⌫") { onKeyPress("⌫") }
        }
    }
}

struct ArrowKeysView: View {
    let onKeyPress: (String) -> Void

    var body: some View {
        VStack(spacing: 2) {
            Button { onKeyPress("↑") } label: {
                arrowKey(icon: "chevron.up")
            }
            .buttonStyle(.plain)

            HStack(spacing: 2) {
                Button { onKeyPress("←") } label: {
                    arrowKey(icon: "chevron.left")
                }
                .buttonStyle(.plain)

                Button { onKeyPress("↓") } label: {
                    arrowKey(icon: "chevron.down")
                }
                .buttonStyle(.plain)

                Button { onKeyPress("→") } label: {
                    arrowKey(icon: "chevron.right")
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func arrowKey(icon: String) -> some View {
        Image(systemName: icon)
            .font(.system(size: 12, weight: .bold))
            .foregroundStyle(Theme.cyberAccentLight)
            .frame(width: 32, height: 22)
            .background(Theme.specialKeyBackground)
            .clipShape(RoundedRectangle(cornerRadius: 4))
    }
}

struct KeyButton: View {
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 14, weight: .medium, design: .monospaced))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 36)
                .background(Theme.keyBackground)
                .clipShape(RoundedRectangle(cornerRadius: 5))
                .overlay(
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(Theme.cyberAccentLight.opacity(0.2), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

struct SpecialKeyButton: View {
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundStyle(Theme.cyberAccentLight)
                .frame(height: 36)
                .frame(minWidth: 32)
                .background(Theme.specialKeyBackground)
                .clipShape(RoundedRectangle(cornerRadius: 5))
                .overlay(
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(Theme.cyberAccentLight.opacity(0.4), lineWidth: 1)
                )
                .shadow(color: Theme.cyberAccentLight.opacity(0.2), radius: 2, x: 0, y: 0)
        }
        .buttonStyle(.plain)
    }
}