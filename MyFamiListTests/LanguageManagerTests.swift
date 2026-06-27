import XCTest
@testable import MyFamiList

// MiscViewModelTests に基本ケースあり。ここでは enum プロパティと localizedString の挙動を追加カバーする。

final class AppLanguageEnumTests: XCTestCase {

    func test_rawValues() {
        XCTAssertEqual(AppLanguage.system.rawValue, "system")
        XCTAssertEqual(AppLanguage.japanese.rawValue, "ja")
        XCTAssertEqual(AppLanguage.english.rawValue, "en")
    }

    func test_caseIterable_has_three_cases() {
        XCTAssertEqual(AppLanguage.allCases.count, 3)
    }

    func test_init_from_rawValue_round_trips() {
        XCTAssertEqual(AppLanguage(rawValue: "ja"), .japanese)
        XCTAssertEqual(AppLanguage(rawValue: "en"), .english)
        XCTAssertEqual(AppLanguage(rawValue: "system"), .system)
        XCTAssertNil(AppLanguage(rawValue: "zh"))
    }

    func test_displayName_japanese() {
        XCTAssertEqual(AppLanguage.japanese.displayName, "日本語")
    }

    func test_displayName_english() {
        XCTAssertEqual(AppLanguage.english.displayName, "English")
    }
}

final class LanguageManagerLocalizationTests: XCTestCase {

    private var sut: LanguageManager!

    override func setUp() {
        super.setUp()
        sut = LanguageManager()
        UserDefaults.standard.removeObject(forKey: LanguageManager.userDefaultsKey)
    }

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: LanguageManager.userDefaultsKey)
        super.tearDown()
    }

    func test_currentLanguage_falls_back_to_system_for_unknown_value() {
        UserDefaults.standard.set("zz", forKey: LanguageManager.userDefaultsKey)
        XCTAssertEqual(sut.currentLanguage, .system)
    }

    func test_localizedString_english_returns_key_unchanged() {
        sut.setLanguage(.english)
        XCTAssertEqual(sut.localizedString("Add Item"), "Add Item")
        XCTAssertEqual(sut.localizedString("__unknown_key__"), "__unknown_key__")
    }

    func test_localizedString_japanese_unknown_key_falls_back_to_key() {
        sut.setLanguage(.japanese)
        let key = "__this_key_does_not_exist_xyz__"
        XCTAssertEqual(sut.localizedString(key), key)
    }

    func test_localizedString_japanese_known_key_returns_nonempty_string() {
        sut.setLanguage(.japanese)
        let result = sut.localizedString("Add Item")
        XCTAssertFalse(result.isEmpty)
    }

    func test_loc_function_english_returns_key() {
        LanguageManager.shared.setLanguage(.english)
        defer { UserDefaults.standard.removeObject(forKey: LanguageManager.userDefaultsKey) }
        XCTAssertEqual(loc("Settings"), "Settings")
    }
}

final class AppThemeCategoryNameTests: XCTestCase {

    func test_categoryName_returns_name_for_known_key() {
        XCTAssertEqual(AppTheme.categoryName("drinks"), "Beverages")
        XCTAssertEqual(AppTheme.categoryName("vegetables"), "Vegetables & Fruits")
        XCTAssertEqual(AppTheme.categoryName("meat"), "Meat & Fish")
    }

    func test_categoryName_falls_back_to_key_for_unknown() {
        XCTAssertEqual(AppTheme.categoryName("custom_cat"), "custom_cat")
    }

    func test_categoryName_japanese_via_loc() {
        LanguageManager.shared.setLanguage(.japanese)
        defer { UserDefaults.standard.removeObject(forKey: LanguageManager.userDefaultsKey) }
        XCTAssertEqual(loc(AppTheme.categoryName("drinks")), "飲料")
        XCTAssertEqual(loc(AppTheme.categoryName("vegetables")), "野菜・果物")
        XCTAssertEqual(loc(AppTheme.categoryName("condiments")), "調味料")
    }

    func test_categoryName_english_via_loc() {
        LanguageManager.shared.setLanguage(.english)
        defer { UserDefaults.standard.removeObject(forKey: LanguageManager.userDefaultsKey) }
        XCTAssertEqual(loc(AppTheme.categoryName("drinks")), "Beverages")
    }
}
