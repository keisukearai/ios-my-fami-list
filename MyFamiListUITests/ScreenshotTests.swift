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
        guard setupGroup() else { return }
        guard createList(name: "今週のスーパー") else { return }

        // リストをタップ（最初のセルをタップ）
        let cell = app.cells.firstMatch
        XCTAssertTrue(cell.waitForExistence(timeout: 8), "リストセルが見つからない")
        cell.tap()

        // 商品追加
        let composer = app.textFields["itemComposer"]
        XCTAssertTrue(composer.waitForExistence(timeout: 8), "コンポーザーが見つからない")

        for itemName in ["🥛 牛乳", "🥚 卵", "🍞 食パン", "🧅 玉ねぎ", "🍎 りんご"] {
            composer.tap()
            composer.typeText(itemName)
            let addBtn = app.buttons["追加"]
            XCTAssertTrue(addBtn.waitForExistence(timeout: 3))
            addBtn.tap()
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
        guard setupGroup() else { return }

        switchTab("メンバー")
        let inviteBtn = app.buttons["inviteButton"]
        XCTAssertTrue(inviteBtn.waitForExistence(timeout: 8), "招待ボタンが見つからない")
        inviteBtn.tap()

        let codeText = app.staticTexts["inviteCodeText"]
        XCTAssertTrue(codeText.waitForExistence(timeout: 5), "招待コードが表示されない")
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
        guard groupBtn.waitForExistence(timeout: 5) else { return false }
        groupBtn.tap()

        guard app.buttons["新しいグループ"].waitForExistence(timeout: 5) else { return false }
        app.buttons["新しいグループ"].tap()

        let tf = app.textFields.firstMatch
        guard tf.waitForExistence(timeout: 5) else { return false }
        tf.tap(); tf.typeText(name)
        app.buttons["作成"].tap()

        // グループ作成完了を待つ
        guard app.buttons["tab_リスト"].waitForExistence(timeout: 10) else { return false }

        // GroupPickerSheet を閉じる
        let closeBtn = app.buttons["閉じる"]
        if closeBtn.waitForExistence(timeout: 3) { closeBtn.tap() }
        sleep(2)
        return true
    }

    /// リストを1つ作成する
    @discardableResult
    private func createList(name: String) -> Bool {
        let addListBtn = app.buttons["リストを追加"]
        guard addListBtn.waitForExistence(timeout: 8) else { return false }
        addListBtn.tap()

        let tf = app.textFields.firstMatch
        guard tf.waitForExistence(timeout: 5) else { return false }
        tf.tap(); tf.typeText(name)

        let confirmBtn = app.navigationBars.buttons["追加"]
        guard confirmBtn.waitForExistence(timeout: 3) else { return false }
        confirmBtn.tap()
        sleep(2)
        return true
    }

    private func snapshot(_ name: String) {
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = name
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }
}
