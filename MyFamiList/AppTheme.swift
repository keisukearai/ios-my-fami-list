import SwiftUI
import UIKit

enum AppTheme {
    private static func adaptive(_ light: String, _ dark: String) -> Color {
        Color(UIColor { tc in
            UIColor(tc.userInterfaceStyle == .dark ? Color(hex: dark) : Color(hex: light))
        })
    }

    private static func adaptiveRGB(
        lr: CGFloat, lg: CGFloat, lb: CGFloat, la: CGFloat,
        dr: CGFloat, dg: CGFloat, db: CGFloat, da: CGFloat
    ) -> Color {
        Color(UIColor { tc in
            tc.userInterfaceStyle == .dark
                ? UIColor(red: dr, green: dg, blue: db, alpha: da)
                : UIColor(red: lr, green: lg, blue: lb, alpha: la)
        })
    }

    static let primary      = Color(hex: "#16A368")
    static let primaryPress = Color(hex: "#138A58")
    static let onPrimary    = Color.white
    static let soft         = adaptive("#E4F4EC", "#1A3028")
    static let softText     = adaptive("#0E7A4D", "#4DC48A")
    static let bg           = adaptive("#EFF4F1", "#121614")

    static let surface  = adaptive("#FFFFFF", "#1E2421")
    static let surface2 = adaptive("#FAFBFA", "#252C28")

    static let text    = adaptive("#16201B", "#E5EDE8")
    static let textSec = adaptiveRGB(lr: 40/255, lg: 54/255, lb: 46/255, la: 0.60,
                                     dr: 185/255, dg: 210/255, db: 195/255, da: 0.70)
    static let textTer = adaptiveRGB(lr: 40/255, lg: 54/255, lb: 46/255, la: 0.34,
                                     dr: 185/255, dg: 210/255, db: 195/255, da: 0.40)

    static let sep      = adaptiveRGB(lr: 40/255, lg: 54/255, lb: 46/255, la: 0.10,
                                      dr: 185/255, dg: 210/255, db: 195/255, da: 0.14)
    static let hairline = adaptiveRGB(lr: 40/255, lg: 54/255, lb: 46/255, la: 0.08,
                                      dr: 185/255, dg: 210/255, db: 195/255, da: 0.10)
    static let fieldBg  = adaptiveRGB(lr: 40/255, lg: 54/255, lb: 46/255, la: 0.05,
                                      dr: 185/255, dg: 210/255, db: 195/255, da: 0.08)

    static let deleteBg   = adaptive("#FBEAE8", "#3D1A17")
    static let deleteText = adaptive("#D9695F", "#FF8A80")

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
