import XCTest

/// App Store 提出用スクリーンショット自動生成
/// 実行: xcodebuild test -only-testing:MyFamiListUITests/ScreenshotTests
final class ScreenshotTests: E2EBaseTest {

    // MARK: - 1. ログイン画面

    func test_screenshot_01_login() {
        app.launchArguments = ["UI_TESTING_CLEAR_AUTH"]
        app.launch()
        XCTAssertTrue(app.buttons["devLoginButton"].waitForExistence(timeout: 5))
        snapshot("01_ログイン画面")
    }

    // MARK: - 2. リスト一覧

    func test_screenshot_02_lists() {
        DevServer.reset(username: "devuser", isPro: true)
        devLoginAndWait()
        guard setupGroup() else { snapshot("02_リスト一覧"); return }
        guard createList(name: "今週のスーパー") else { snapshot("02_リスト一覧"); return }
        guard createList(name: "薬局リスト") else { snapshot("02_リスト一覧"); return }
        sleep(1)
        snapshot("02_リスト一覧")
    }

    // MARK: - 3. 買い物中（リスト詳細）

    func test_screenshot_03_shopping() {
        DevServer.reset(username: "devuser", isPro: true)
        devLoginAndWait()
        guard setupGroup() else {
            snapshot("03_買い物中")
            XCTFail("setupGroup failed")
            return
        }
        guard createList(name: "今週のスーパー") else {
            snapshot("03_買い物中")
            XCTFail("createList failed")
            return
        }

        // リストをタップ（最初のセルをタップ）
        let cell = app.cells.firstMatch
        guard cell.waitForExistence(timeout: 8) else {
            snapshot("03_買い物中")
            XCTFail("list cell not found")
            return
        }
        cell.tap()

        // 商品追加
        let composer = app.textFields["itemComposer"]
        guard composer.waitForExistence(timeout: 8) else {
            snapshot("03_買い物中")
            XCTFail("itemComposer not found")
            return
        }

        for itemName in ["🥛 牛乳", "🥚 卵", "🍞 食パン", "🧅 玉ねぎ", "🍎 りんご"] {
            composer.tap()
            composer.typeText(itemName)
            let addBtn = app.buttons["追加"]
            if addBtn.waitForExistence(timeout: 3) { addBtn.tap() }
            sleep(1)
        }

        // 最初の2つをチェック
        let milk = app.staticTexts["🥛 牛乳"]
        if milk.waitForExistence(timeout: 5) { milk.tap(); sleep(1) }
        let egg = app.staticTexts["🥚 卵"]
        if egg.waitForExistence(timeout: 3) { egg.tap(); sleep(1) }

        app.swipeDown()
        sleep(1)
        snapshot("03_買い物中")
    }

    // MARK: - 4. メンバー・招待コード

    func test_screenshot_04_members() {
        DevServer.reset(username: "devuser", isPro: true)
        devLoginAndWait()
        guard setupGroup() else {
            snapshot("04_招待コード")
            XCTFail("setupGroup failed")
            return
        }

        switchTab("メンバー")
        let inviteBtn = app.buttons["inviteButton"]
        guard inviteBtn.waitForExistence(timeout: 8) else {
            snapshot("04_招待コード")
            XCTFail("inviteButton not found")
            return
        }
        inviteBtn.tap()

        let codeText = app.staticTexts["inviteCodeText"]
        guard codeText.waitForExistence(timeout: 5) else {
            snapshot("04_招待コード")
            XCTFail("inviteCodeText not found")
            return
        }
        snapshot("04_招待コード")
        app.buttons["閉じる"].tap()
    }

    // MARK: - 5. 設定画面（Pro プラン）

    func test_screenshot_05_settings() {
        DevServer.reset(username: "devuser", isPro: true)
        devLoginAndWait()
        switchTab("設定")
        sleep(1)
        snapshot("05_設定画面_Pro")
    }

    // MARK: - Helpers

    /// グループを作成してピッカーを閉じる
    @discardableResult
    private func setupGroup(name: String = "山田家の買い物") -> Bool {
        // グループピッカーを開く
        let groupBtn = app.buttons.matching(
            NSPredicate(format: "label CONTAINS 'グループ' OR label CONTAINS 'なし'")
        ).firstMatch
        guard groupBtn.waitForExistence(timeout: 8) else { return false }
        groupBtn.tap()
        sleep(2)

        let newGroupBtn = app.buttons["新しいグループ"]
        guard newGroupBtn.exists else { return false }
        newGroupBtn.tap()

        let tf = app.textFields.firstMatch
        guard tf.waitForExistence(timeout: 8) else { return false }
        tf.tap(); tf.typeText(name)
        app.buttons["グループを作成"].firstMatch.tap()
        sleep(3)

        // GroupPickerSheet を閉じる
        let closeBtn = app.buttons["閉じる"]
        if closeBtn.waitForExistence(timeout: 5) { closeBtn.tap() }
        sleep(2)
        return true
    }

    /// リストを1つ作成する
    @discardableResult
    private func createList(name: String) -> Bool {
        let addListBtn = app.buttons["リストを追加"]
        guard addListBtn.waitForExistence(timeout: 15) else { return false }
        addListBtn.tap()

        let tf = app.textFields.firstMatch
        guard tf.waitForExistence(timeout: 10) else { return false }
        tf.tap(); tf.typeText(name)

        let confirmBtn = app.navigationBars.buttons["追加"]
        guard confirmBtn.waitForExistence(timeout: 8) else { return false }
        confirmBtn.tap()
        sleep(2)
        return true
    }

    private func snapshot(_ name: String) {
        let screenshot = app.screenshot()

        // XCTAttachment にも保存（xcresult 内）
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)

        // プロジェクト直下の Screenshots/ フォルダに PNG として書き出す
        let projectRoot = URL(fileURLWithPath: #file)
            .deletingLastPathComponent()  // MyFamiListUITests/
            .deletingLastPathComponent()  // MyFamiList/
            .deletingLastPathComponent()  // FamiList（プロジェクトルート）
        let screenshotsDir = projectRoot.appendingPathComponent("Screenshots")
        try? FileManager.default.createDirectory(at: screenshotsDir, withIntermediateDirectories: true)
        let pngURL = screenshotsDir.appendingPathComponent("\(name).png")
        try? screenshot.pngRepresentation.write(to: pngURL)
    }
}
