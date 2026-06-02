import SwiftUI

struct AvatarView: View {
    let name: String
    let size: CGFloat
    var colorHex: String? = nil

    private static let palette = [
        "#16A368", "#D9695F", "#5690C9",
        "#E0A03A", "#B179B0", "#D981A6", "#7C8AA1",
    ]

    private var initials: String {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        let parts = trimmed.split(separator: " ")
        if parts.count >= 2 {
            return String(parts[0].prefix(1)) + String(parts[1].prefix(1))
        }
        return String(trimmed.prefix(2))
    }

    private var bgColor: Color {
        if let hex = colorHex { return Color(hex: hex) }
        let seed = name.unicodeScalars.reduce(0) { $0 &+ Int($1.value) }
        return Color(hex: Self.palette[abs(seed) % Self.palette.count])
    }

    var body: some View {
        ZStack {
            Circle().fill(bgColor)
            Text(initials.isEmpty ? "?" : initials.uppercased())
                .font(.system(size: size * 0.38, weight: .semibold))
                .foregroundStyle(.white)
        }
        .frame(width: size, height: size)
    }
}

#Preview {
    HStack {
        AvatarView(name: "山田 太郎", size: 44)
        AvatarView(name: "花子", size: 44, colorHex: "#D9695F")
        AvatarView(name: "K", size: 32)
    }
    .padding()
}
