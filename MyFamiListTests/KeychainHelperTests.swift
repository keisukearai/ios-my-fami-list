import XCTest
@testable import MyFamiList

final class KeychainHelperTests: XCTestCase {

    private let helper = KeychainHelper.shared
    private let key1 = "com.test.keychain.key1"
    private let key2 = "com.test.keychain.key2"

    override func setUp() {
        super.setUp()
        helper.delete(key1)
        helper.delete(key2)
    }

    override func tearDown() {
        helper.delete(key1)
        helper.delete(key2)
        super.tearDown()
    }

    // MARK: - get / set

    func test_set_and_get_roundtrip() {
        helper.set(key1, value: "hello")
        XCTAssertEqual(helper.get(key1), "hello")
    }

    func test_get_nonexistent_key_returns_nil() {
        XCTAssertNil(helper.get(key1))
    }

    func test_overwrite_updates_stored_value() {
        helper.set(key1, value: "first")
        helper.set(key1, value: "second")
        XCTAssertEqual(helper.get(key1), "second")
    }

    func test_different_keys_are_independent() {
        helper.set(key1, value: "value1")
        helper.set(key2, value: "value2")
        XCTAssertEqual(helper.get(key1), "value1")
        XCTAssertEqual(helper.get(key2), "value2")
    }

    func test_stores_unicode_and_emoji() {
        let value = "日本語テスト 🛒"
        helper.set(key1, value: value)
        XCTAssertEqual(helper.get(key1), value)
    }

    func test_stores_empty_string() {
        helper.set(key1, value: "")
        XCTAssertEqual(helper.get(key1), "")
    }

    // MARK: - delete

    func test_delete_removes_stored_value() {
        helper.set(key1, value: "temporary")
        helper.delete(key1)
        XCTAssertNil(helper.get(key1))
    }

    func test_delete_nonexistent_key_does_not_crash() {
        helper.delete("com.test.keychain.nonexistent_xyz")
    }

    func test_delete_only_removes_targeted_key() {
        helper.set(key1, value: "keep_me")
        helper.set(key2, value: "delete_me")
        helper.delete(key2)
        XCTAssertEqual(helper.get(key1), "keep_me")
        XCTAssertNil(helper.get(key2))
    }
}
