import Foundation

extension Notification.Name {
    static let languageDidChange = Notification.Name("app.languageDidChange")
}

enum AppLanguage: String, CaseIterable {
    case system = "system"
    case japanese = "ja"
    case english = "en"

    var displayName: String {
        switch self {
        case .system:   return loc("System Default")
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

    private var cachedCode: String?
    private var cachedLprojBundle: Bundle?

    init() {}

    func setLanguage(_ language: AppLanguage) {
        UserDefaults.standard.set(language.rawValue, forKey: Self.userDefaultsKey)
        UserDefaults.standard.synchronize()
        cachedCode = nil
        cachedLprojBundle = nil
        NotificationCenter.default.post(name: .languageDidChange, object: nil)
    }

    func localizedString(_ key: String, table: String? = nil) -> String {
        let lang = currentLanguage
        switch lang {
        case .english:
            return key
        case .japanese:
            if let bundle = lprojBundle(for: "ja") {
                return bundle.localizedString(forKey: key, value: key, table: table)
            }
            return key
        case .system:
            let code = Locale.current.language.languageCode?.identifier ?? "ja"
            if let bundle = lprojBundle(for: code) {
                return bundle.localizedString(forKey: key, value: key, table: table)
            }
            return key
        }
    }

    private func lprojBundle(for code: String) -> Bundle? {
        if cachedCode == code { return cachedLprojBundle }
        let url = Bundle.main.bundleURL.appendingPathComponent("\(code).lproj")
        cachedLprojBundle = Bundle(url: url)
        cachedCode = code
        return cachedLprojBundle
    }
}

/// LanguageManager 経由でローカライズ文字列を取得する。
/// String(localized:) の代わりに使用することで、再起動不要の即時言語切り替えを実現する。
func loc(_ key: String, table: String? = nil) -> String {
    LanguageManager.shared.localizedString(key, table: table)
}
