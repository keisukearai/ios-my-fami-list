import XCTest
@testable import MyFamiList

// PurchaseService のうち、StoreKit / App Store に依存しない純粋ロジックを検証する。
// 実際の purchase() / restore() は SKTestSession + 実機 Sandbox が必要なため対象外
// （リリース前チェックリストの「実機テスト」バケットに残す）。
@MainActor
final class PurchaseServiceTests: XCTestCase {

    override func tearDown() async throws {
        await Task.yield()
        try await super.tearDown()
    }

    func test_productID_matches_app_store_connect() {
        XCTAssertEqual(PurchaseService.productID, "com.keisukearai.myfamilist.premium")
    }

    func test_new_service_is_not_pro() {
        let svc = PurchaseService()
        XCTAssertFalse(svc.isPro, "初期状態は無料プラン")
    }

    func test_syncFromServer_upgrades_to_pro() {
        let svc = PurchaseService()
        svc.syncFromServer(isPro: true)
        XCTAssertTrue(svc.isPro, "サーバーが Pro を返したら反映される")
    }

    func test_syncFromServer_false_keeps_free() {
        let svc = PurchaseService()
        svc.syncFromServer(isPro: false)
        XCTAssertFalse(svc.isPro)
    }

    // サーバー側 isPro=false でローカルの Pro を降格させてはいけない
    // （別デバイス購入直後にサーバー反映が遅れるケースを守る）
    func test_syncFromServer_does_not_downgrade_existing_pro() {
        let svc = PurchaseService()
        svc.syncFromServer(isPro: true)
        XCTAssertTrue(svc.isPro)

        svc.syncFromServer(isPro: false)
        XCTAssertTrue(svc.isPro, "一度 Pro になったらサーバーの false で降格しない")
    }

    func test_purchaseError_descriptions_are_localized() {
        XCTAssertEqual(
            PurchaseService.PurchaseError.productNotFound.errorDescription,
            loc("Product not found")
        )
        XCTAssertEqual(
            PurchaseService.PurchaseError.failedVerification.errorDescription,
            loc("Purchase verification failed")
        )
    }
}
