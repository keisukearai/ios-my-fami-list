import Foundation

enum AppLanguage: String, CaseIterable {
    case system = "system"
    case japanese = "ja"
    case english = "en"

    var displayName: String {
        switch self {
        case .system:   return String(localized: "System Default")
        case .japanese: return "日本語"
        case .english:  return "English"
        }
    }

    var acceptLanguageHeader: String {
        switch self {
        case .system:   return Locale.current.language.languageCode?.identifier ?? "ja"
        case .japanese: return "ja"
        case .english:  return "en"
        }
    }
}

final class LanguageManager {
    static let shared = LanguageManager()
    static let userDefaultsKey = "app_language"

    var currentLanguage: AppLanguage {
        AppLanguage(rawValue: UserDefaults.standard.string(forKey: Self.userDefaultsKey) ?? "system") ?? .system
    }

    func setLanguage(_ language: AppLanguage) {
        UserDefaults.standard.set(language.rawValue, forKey: Self.userDefaultsKey)
        switch language {
        case .system:
            UserDefaults.standard.removeObject(forKey: "AppleLanguages")
        case .japanese:
            UserDefaults.standard.set(["ja"], forKey: "AppleLanguages")
        case .english:
            UserDefaults.standard.set(["en"], forKey: "AppleLanguages")
        }
        UserDefaults.standard.synchronize()
    }
}
