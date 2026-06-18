import XCTest
@testable import MyFamiList

// MiscViewModelTests に基本ケースあり。ここでは未カバーのエッジケースを追加する。
final class InviteHandlerEdgeCaseTests: XCTestCase {

    private var sut: InviteHandler!

    override func setUp() {
        super.setUp()
        sut = InviteHandler()
    }

    private func url(_ string: String) -> URL { URL(string: string)! }

    func test_mixed_case_code_is_uppercased() {
        _ = sut.handle(url: url("https://ios.kotoragk.com/invite/Ab3xYz"))
        XCTAssertEqual(sut.pendingCode, "AB3XYZ")
    }

    func test_handle_overwrites_previous_pending_code() {
        _ = sut.handle(url: url("https://ios.kotoragk.com/invite/FIRST1"))
        _ = sut.handle(url: url("https://ios.kotoragk.com/invite/SECOND"))
        XCTAssertEqual(sut.pendingCode, "SECOND")
    }

    func test_root_path_returns_false() {
        XCTAssertFalse(sut.handle(url: url("https://ios.kotoragk.com/")))
        XCTAssertNil(sut.pendingCode)
    }

    func test_api_path_returns_false() {
        XCTAssertFalse(sut.handle(url: url("https://ios.kotoragk.com/api/fami_list/groups/")))
        XCTAssertNil(sut.pendingCode)
    }
}
