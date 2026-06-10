import SwiftUI

struct Theme {
    // MARK: - Main Colors
    static let cyberBackground = Color(red: 0.05, green: 0.08, blue: 0.12)
    static let cyberBackgroundDark = Color(red: 0.02, green: 0.04, blue: 0.08)
    static let cyberAccent = Color(red: 0.0, green: 0.9, blue: 0.7)
    static let cyberAccentLight = Color(red: 0.0, green: 0.95, blue: 0.75)
    static let terminalGreen = Color(red: 0.0, green: 0.9, blue: 0.4)
    static let terminalGreenLight = Color(red: 0.0, green: 0.95, blue: 0.45)

    // MARK: - Keyboard Colors
    static let keyboardBackground = Color(red: 0.02, green: 0.04, blue: 0.08)
    static let keyBackground = Color(red: 0.08, green: 0.12, blue: 0.16)
    static let specialKeyBackground = Color(red: 0.1, green: 0.15, blue: 0.2)

    // MARK: - Semantic Colors
    static let error = Color.red
    static let success = terminalGreen
    static let warning = Color.yellow

    // MARK: - Text Colors
    static let textPrimary = Color.white
    static let textSecondary = Color.gray
    static let textAccent = cyberAccent
}