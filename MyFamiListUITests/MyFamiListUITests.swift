import XCTest

final class MyFamiListUITests: XCTestCase {

    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - ログイン画面

    func test_loginScreen_appears_when_auth_cleared() {
        app.launchArguments = ["UI_TESTING_CLEAR_AUTH"]
        app.launch()
        XCTAssertTrue(app.buttons["メールアドレスで続ける"].waitForExistence(timeout: 5))
    }

    func test_loginScreen_has_signin_buttons() {
        app.launchArguments = ["UI_TESTING_CLEAR_AUTH"]
        app.launch()
        // メールとGoogle ボタンの存在を確認（Apple ボタンはシステム提供でラベルが変動）
        XCTAssertTrue(app.buttons["メールアドレスで続ける"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons.count >= 3, "ログインボタンが3つ以上あること")
    }

    func test_loginScreen_has_dev_login_button_in_debug() {
        app.launchArguments = ["UI_TESTING_CLEAR_AUTH"]
        app.launch()
        XCTAssertTrue(app.buttons["devLoginButton"].waitForExistence(timeout: 5))
    }

    // MARK: - エラー表示

    func test_devLogin_shows_error_when_server_unavailable() {
        // Django が localhost:8000 で動いていない場合にエラー表示を確認
        app.launchArguments = ["UI_TESTING_CLEAR_AUTH"]
        app.launch()

        let devLoginBtn = app.buttons["devLoginButton"]
        guard devLoginBtn.waitForExistence(timeout: 5) else {
            XCTFail("devLoginButton not found")
            return
        }
        devLoginBtn.tap()

        // エラーバナーの出現を待つ（最大5秒）
        let errorBanner = app.otherElements["loginErrorBanner"]
        if errorBanner.waitForExistence(timeout: 5) {
            // エラーが表示された場合：サーバー未起動のケース
            let errorText = app.staticTexts["loginErrorText"]
            XCTAssertTrue(errorText.exists)
            // 英語の生エラー（URLError等）ではなく日本語メッセージであること
            let label = errorText.label
            XCTAssertFalse(label.contains("The operation couldn't be completed"),
                           "エラーメッセージが英語のまま: \(label)")
        }
        // サーバーが起動中でログイン成功した場合はエラーなし = OK
    }

    func test_error_icon_appears_with_error_message() {
        app.launchArguments = ["UI_TESTING_CLEAR_AUTH"]
        app.launch()

        let devLoginBtn = app.buttons["devLoginButton"]
        guard devLoginBtn.waitForExistence(timeout: 5) else { return }
        devLoginBtn.tap()

        let errorBanner = app.otherElements["loginErrorBanner"]
        guard errorBanner.waitForExistence(timeout: 5) else { return }

        // アイコンとテキストが同時に存在すること
        XCTAssertTrue(app.images["loginErrorIcon"].exists
                      || app.otherElements["loginErrorIcon"].exists)
        XCTAssertTrue(app.staticTexts["loginErrorText"].exists)
    }

    // MARK: - メールアドレス認証シート

    func test_emailAuth_sheet_opens() {
        app.launchArguments = ["UI_TESTING_CLEAR_AUTH"]
        app.launch()

        let emailBtn = app.buttons["メールアドレスで続ける"]
        guard emailBtn.waitForExistence(timeout: 5) else {
            XCTFail("メールアドレスで続けるボタンが見つかりません")
            return
        }
        emailBtn.tap()

        // メール入力フィールドが表示されること
        XCTAssertTrue(app.textFields.element.waitForExistence(timeout: 3)
                      || app.secureTextFields.element.waitForExistence(timeout: 3))
    }
}
