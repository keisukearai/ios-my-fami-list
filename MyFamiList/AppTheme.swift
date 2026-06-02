import SwiftUI

enum AppTheme {
    static let primary      = Color(hex: "#16A368")
    static let primaryPress = Color(hex: "#138A58")
    static let onPrimary    = Color.white
    static let soft         = Color(hex: "#E4F4EC")
    static let softText     = Color(hex: "#0E7A4D")
    static let bg           = Color(hex: "#EFF4F1")

    static let surface  = Color.white
    static let surface2 = Color(hex: "#FAFBFA")

    static let text    = Color(hex: "#16201B")
    static let textSec = Color(red: 40/255, green: 54/255, blue: 46/255).opacity(0.60)
    static let textTer = Color(red: 40/255, green: 54/255, blue: 46/255).opacity(0.34)

    static let sep      = Color(red: 40/255, green: 54/255, blue: 46/255).opacity(0.10)
    static let hairline = Color(red: 40/255, green: 54/255, blue: 46/255).opacity(0.08)
    static let fieldBg  = Color(red: 40/255, green: 54/255, blue: 46/255).opacity(0.05)

    static let shadowLight = Color(red: 20/255, green: 40/255, blue: 30/255)

    static let rCard:  CGFloat = 20
    static let rBtn:   CGFloat = 14
    static let rChip:  CGFloat = 10
    static let rSheet: CGFloat = 30
    static let rField: CGFloat = 13
    static let rTiny:  CGFloat = 8

    static let rowH:   CGFloat = 52
    static let padY:   CGFloat = 12
    static let gap:    CGFloat = 11
    static let secGap: CGFloat = 24
    static let fs:     CGFloat = 16.5

    static let categories: [(name: String, color: Color)] = [
        ("野菜・果物", Color(hex: "#54A862")),
        ("肉・魚",     Color(hex: "#D9695F")),
        ("乳製品・卵", Color(hex: "#E0A03A")),
        ("パン・米",   Color(hex: "#C5934F")),
        ("飲料",       Color(hex: "#5690C9")),
        ("調味料",     Color(hex: "#B179B0")),
        ("お菓子",     Color(hex: "#D981A6")),
        ("日用品",     Color(hex: "#7C8AA1")),
        ("その他",     Color(hex: "#98A0A4")),
    ]

    static func categoryColor(_ name: String) -> Color {
        categories.first { $0.name == name }?.color ?? Color(hex: "#98A0A4")
    }
}

extension View {
    func cardShadow() -> some View {
        self
            .shadow(color: AppTheme.shadowLight.opacity(0.05), radius: 1, x: 0, y: 1)
            .shadow(color: AppTheme.shadowLight.opacity(0.07), radius: 13, x: 0, y: 8)
    }
}
