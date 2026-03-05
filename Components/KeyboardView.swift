import SwiftUI

struct TerminalKeyboardView: View {
    let onKeyPress: (String) -> Void
    
    private let cyberBackground = Color(red: 0.02, green: 0.04, blue: 0.08)
    private let cyberAccent = Color(red: 0.0, green: 0.95, blue: 0.75)
    private let keyBackground = Color(red: 0.08, green: 0.12, blue: 0.18)
    private let specialKeyBackground = Color(red: 0.12, green: 0.16, blue: 0.24)
    
    private let keys1 = ["q", "w", "e", "r", "t", "y", "u", "i", "o", "p"]
    private let keys2 = ["a", "s", "d", "f", "g", "h", "j", "k", "l"]
    private let keys3 = ["z", "x", "c", "v", "b", "n", "m"]
    
    var body: some View {
        VStack(spacing: 6) {
            specialKeysRow
            
            HStack(spacing: 4) {
                ForEach(keys1, id: \.self) { key in
                    KeyButton(label: key, accent: cyberAccent, background: keyBackground) { onKeyPress(key) }
                }
            }
            
            HStack(spacing: 4) {
                ForEach(keys2, id: \.self) { key in
                    KeyButton(label: key, accent: cyberAccent, background: keyBackground) { onKeyPress(key) }
                }
            }
            
            HStack(spacing: 4) {
                ForEach(keys3, id: \.self) { key in
                    KeyButton(label: key, accent: cyberAccent, background: keyBackground) { onKeyPress(key) }
                }
            }
            
            bottomRow
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 8)
        .background(cyberBackground)
    }
    
    private var specialKeysRow: some View {
        HStack(spacing: 4) {
            SpecialKeyButton(label: "Ctrl", width: 50, accent: cyberAccent, background: specialKeyBackground) { onKeyPress("Ctrl") }
            SpecialKeyButton(label: "Tab", width: 45, accent: cyberAccent, background: specialKeyBackground) { onKeyPress("Tab") }
            SpecialKeyButton(label: "Esc", width: 40, accent: cyberAccent, background: specialKeyBackground) { onKeyPress("Esc") }
            
            Spacer()
            
            ArrowKeysView(onKeyPress: onKeyPress)
            
            Spacer()
            
            SpecialKeyButton(label: "Enter", width: 55, accent: cyberAccent, background: specialKeyBackground) { onKeyPress("Enter") }
        }
    }
    
    private var bottomRow: some View {
        HStack(spacing: 4) {
            SpecialKeyButton(label: "Alt", width: 40, accent: cyberAccent, background: specialKeyBackground) { onKeyPress("Alt") }
            
            KeyButton(label: "0", accent: cyberAccent, background: keyBackground) { onKeyPress("0") }
            KeyButton(label: "1", accent: cyberAccent, background: keyBackground) { onKeyPress("1") }
            KeyButton(label: "2", accent: cyberAccent, background: keyBackground) { onKeyPress("2") }
            KeyButton(label: "3", accent: cyberAccent, background: keyBackground) { onKeyPress("3") }
            KeyButton(label: "4", accent: cyberAccent, background: keyBackground) { onKeyPress("4") }
            KeyButton(label: "5", accent: cyberAccent, background: keyBackground) { onKeyPress("5") }
            KeyButton(label: "6", accent: cyberAccent, background: keyBackground) { onKeyPress("6") }
            KeyButton(label: "7", accent: cyberAccent, background: keyBackground) { onKeyPress("7") }
            KeyButton(label: "8", accent: cyberAccent, background: keyBackground) { onKeyPress("8") }
            KeyButton(label: "9", accent: cyberAccent, background: keyBackground) { onKeyPress("9") }
            
            KeyButton(label: "-", accent: cyberAccent, background: keyBackground) { onKeyPress("-") }
            KeyButton(label: "=", accent: cyberAccent, background: keyBackground) { onKeyPress("=") }
            
            SpecialKeyButton(label: "⌫", width: 55, accent: cyberAccent, background: specialKeyBackground) { onKeyPress("⌫") }
        }
    }
}

struct ArrowKeysView: View {
    let onKeyPress: (String) -> Void
    
    private let cyberAccent = Color(red: 0.0, green: 0.95, blue: 0.75)
    private let specialKeyBackground = Color(red: 0.12, green: 0.16, blue: 0.24)
    
    var body: some View {
        VStack(spacing: 2) {
            Button { onKeyPress("↑") } label: {
                Image(systemName: "chevron.up")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(cyberAccent)
                    .frame(width: 28, height: 22)
                    .background(specialKeyBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }
            .buttonStyle(.plain)
            
            HStack(spacing: 2) {
                Button { onKeyPress("←") } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(cyberAccent)
                        .frame(width: 28, height: 22)
                        .background(specialKeyBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
                .buttonStyle(.plain)
                
                Button { onKeyPress("↓") } label: {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(cyberAccent)
                        .frame(width: 28, height: 22)
                        .background(specialKeyBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
                .buttonStyle(.plain)
                
                Button { onKeyPress("→") } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(cyberAccent)
                        .frame(width: 28, height: 22)
                        .background(specialKeyBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
                .buttonStyle(.plain)
            }
        }
    }
}

struct KeyButton: View {
    let label: String
    let accent: Color
    let background: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 16, weight: .medium, design: .monospaced))
                .foregroundStyle(.white)
                .frame(width: 28, height: 36)
                .background(background)
                .clipShape(RoundedRectangle(cornerRadius: 5))
                .overlay(
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(accent.opacity(0.2), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

struct SpecialKeyButton: View {
    let label: String
    let width: CGFloat
    let accent: Color
    let background: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundStyle(accent)
                .frame(width: width, height: 36)
                .background(background)
                .clipShape(RoundedRectangle(cornerRadius: 5))
                .overlay(
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(accent.opacity(0.4), lineWidth: 1)
                )
                .shadow(color: accent.opacity(0.2), radius: 2, x: 0, y: 0)
        }
        .buttonStyle(.plain)
    }
}
