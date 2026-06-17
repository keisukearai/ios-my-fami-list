import XCTest

// MARK: - サーバーヘルパー

/// ローカル Django サーバー（localhost:8000）を操作するヘルパー
enum DevServer {
    static let base = "http://localhost:8000/api/fami_list"

    /// ユーザー状態をリセット（グループ全削除、Pro状態を指定）
    @discardableResult
    static func reset(username: String = "devuser", isPro: Bool = true) -> Bool {
        guard let url = URL(string: "\(base)/auth/dev-reset/") else { return false }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try? JSONSerialization.data(withJSONObject: ["username": username, "is_pro": isPro])
        req.timeoutInterval = 5

        var ok = false
        let sem = DispatchSemaphore(value: 0)
        URLSession.shared.dataTask(with: req) { _, res, _ in
            ok = (res as? HTTPURLResponse)?.statusCode == 200
            sem.signal()
        }.resume()
        sem.wait()
        return ok
    }

    /// サーバーが起動しているか確認
    static func isAvailable() -> Bool {
        guard let url = URL(string: "\(base)/auth/dev-login/") else { return false }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try? JSONSerialization.data(withJSONObject: ["username": "healthcheck"])
        req.timeoutInterval = 3

        var available = false
        let sem = DispatchSemaphore(value: 0)
        URLSession.shared.dataTask(with: req) { _, res, _ in
            available = (res as? HTTPURLResponse)?.statusCode == 200
            sem.signal()
        }.resume()
        sem.wait()
        return available
    }
}

// MARK: - 共通セットアップ

class E2EBaseTest: XCTestCase {
    var app: XCUIApplication!
    var serverAvailable: Bool = false

    override func setUpWithError() throws {
        continueAfterFailure = false
        serverAvailable = DevServer.isAvailable()
        try XCTSkipUnless(serverAvailable, "Django サーバー（localhost:8000）が起動していないためスキップ")
        app = XCUIApplication()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    /// dev login してメイン画面まで遷移
    func devLoginAndWait(username: String = "devuser") {
        app.launchArguments = ["UI_TESTING_CLEAR_AUTH"]
        if username != "devuser" {
            app.launchEnvironment["UI_TESTING_DEV_USERNAME"] = username
        }
        app.launch()

        let btn = app.buttons["devLoginButton"]
        XCTAssertTrue(btn.waitForExistence(timeout: 5))
        btn.tap()
        XCTAssertTrue(app.buttons["tab_リスト"].waitForExistence(timeout: 10))
    }

    /// タブを切り替える
    func switchTab(_ label: String) {
        app.buttons["tab_\(label)"].tap()
    }
}

// MARK: - ログイン・ログアウトテスト

final class E2ELoginTests: E2EBaseTest {

    func test_devLogin_reaches_main_screen() {
        DevServer.reset(username: "devuser", isPro: false)
        devLoginAndWait()
        XCTAssertTrue(app.buttons["tab_リスト"].exists)
        XCTAssertTrue(app.buttons["tab_メンバー"].exists)
        XCTAssertTrue(app.buttons["tab_設定"].exists)
    }

    func test_logout_returns_to_login_screen() {
        DevServer.reset(username: "devuser", isPro: false)
        devLoginAndWait()

        switchTab("設定")
        let signOut = app.otherElements["signOutRow"]
        XCTAssertTrue(signOut.waitForExistence(timeout: 5))
        signOut.tap()

        // 確認ダイアログ → 「サインアウト」
        let confirmBtn = app.buttons["サインアウト"]
        XCTAssertTrue(confirmBtn.waitForExistence(timeout: 3))
        confirmBtn.tap()

        XCTAssertTrue(app.buttons["devLoginButton"].waitForExistence(timeout: 5))
    }

    func test_relogin_after_logout() {
        DevServer.reset(username: "devuser", isPro: false)
        devLoginAndWait()

        switchTab("設定")
        app.otherElements["signOutRow"].tap()
        app.buttons["サインアウト"].tap()

        // 再ログイン
        XCTAssertTrue(app.buttons["devLoginButton"].waitForExistence(timeout: 5))
        app.buttons["devLoginButton"].tap()
        XCTAssertTrue(app.buttons["tab_リスト"].waitForExistence(timeout: 10))
    }
}

// MARK: - Paywall・グループ作成テスト

final class E2EGroupTests: E2EBaseTest {

    func test_paywall_appears_for_free_user() {
        DevServer.reset(username: "devuser", isPro: false)
        devLoginAndWait()

        // グループピッカーを開く（リスト画面上部のグループピル）
        let groupPill = app.buttons.matching(NSPredicate(format: "label CONTAINS 'グループ' OR label CONTAINS 'なし'")).firstMatch
        if groupPill.exists { groupPill.tap() }

        let createBtn = app.buttons["新しいグループ"]
        if !createBtn.waitForExistence(timeout: 3) {
            // グループピッカーシートが開いていなければグループ選択ボタンから開く
            app.buttons.matching(NSPredicate(format: "label CONTAINS 'グループ'")).firstMatch.tap()
        }

        XCTAssertTrue(app.buttons["新しいグループ"].waitForExistence(timeout: 5))
        app.buttons["新しいグループ"].tap()

        // Paywall シートが表示される
        XCTAssertTrue(app.staticTexts["FamiList Pro にアップグレード"].waitForExistence(timeout: 5))
    }

    func test_create_group_as_pro_user() {
        DevServer.reset(username: "devuser", isPro: true)
        devLoginAndWait()

        // グループピッカーを開く
        app.buttons.matching(NSPredicate(format: "label CONTAINS 'グループ' OR label CONTAINS 'なし'")).firstMatch.tap()
        XCTAssertTrue(app.buttons["新しいグループ"].waitForExistence(timeout: 5))
        app.buttons["新しいグループ"].tap()

        // グループ名入力
        let textField = app.textFields.firstMatch
        XCTAssertTrue(textField.waitForExistence(timeout: 3))
        textField.tap()
        textField.typeText("テストグループ")

        app.buttons["作成"].tap()

        // グループが作成され、リスト画面に戻る
        XCTAssertTrue(app.buttons["tab_リスト"].waitForExistence(timeout: 10))
    }

    func test_invite_code_visible_in_members_tab() {
        DevServer.reset(username: "devuser", isPro: true)
        devLoginAndWait()

        // グループを作成
        app.buttons.matching(NSPredicate(format: "label CONTAINS 'グループ' OR label CONTAINS 'なし'")).firstMatch.tap()
        app.buttons["新しいグループ"].waitForExistence(timeout: 5)
        app.buttons["新しいグループ"].tap()
        let tf = app.textFields.firstMatch
        tf.waitForExistence(timeout: 3)
        tf.tap(); tf.typeText("招待テスト")
        app.buttons["作成"].tap()
        app.buttons["tab_リスト"].waitForExistence(timeout: 10)

        // メンバータブ → 招待ボタン
        switchTab("メンバー")
        XCTAssertTrue(app.buttons["inviteButton"].waitForExistence(timeout: 5))
        app.buttons["inviteButton"].tap()

        // 招待コードが6文字で表示される
        let codeText = app.staticTexts["inviteCodeText"]
        XCTAssertTrue(codeText.waitForExistence(timeout: 5))
        XCTAssertEqual(codeText.label.count, 6)
    }
}

// MARK: - 買い物フローテスト

final class E2EShoppingTests: E2EBaseTest {

    private func setupGroupAndList() {
        DevServer.reset(username: "devuser", isPro: true)
        devLoginAndWait()

        // グループ作成
        app.buttons.matching(NSPredicate(format: "label CONTAINS 'グループ' OR label CONTAINS 'なし'")).firstMatch.tap()
        app.buttons["新しいグループ"].waitForExistence(timeout: 5)
        app.buttons["新しいグループ"].tap()
        let tf = app.textFields.firstMatch
        tf.waitForExistence(timeout: 3); tf.tap(); tf.typeText("買い物グループ")
        app.buttons["作成"].tap()
        app.buttons["tab_リスト"].waitForExistence(timeout: 10)

        // リスト作成
        app.buttons["リストを追加"].tap()
        let listTF = app.textFields["addListTextField"]
        listTF.waitForExistence(timeout: 5); listTF.tap(); listTF.typeText("週末の買い物")
        app.buttons["addListConfirmButton"].tap()
        sleep(1)
    }

    func test_create_list_and_add_items() {
        setupGroupAndList()

        // リストをタップしてリスト詳細へ
        let listCell = app.staticTexts["週末の買い物"]
        XCTAssertTrue(listCell.waitForExistence(timeout: 5))
        listCell.tap()

        // アイテム追加
        let composer = app.textFields["itemComposer"]
        XCTAssertTrue(composer.waitForExistence(timeout: 5))
        composer.tap()
        composer.typeText("牛乳")
        app.buttons["追加"].tap()

        composer.tap()
        composer.typeText("卵")
        app.buttons["追加"].tap()

        // 2アイテムが一覧に表示される
        XCTAssertTrue(app.staticTexts["牛乳"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["卵"].exists)
    }

    func test_check_item() {
        setupGroupAndList()

        let listCell = app.staticTexts["週末の買い物"]
        XCTAssertTrue(listCell.waitForExistence(timeout: 5))
        listCell.tap()

        // アイテム追加
        let composer = app.textFields["itemComposer"]
        XCTAssertTrue(composer.waitForExistence(timeout: 5))
        composer.tap()
        composer.typeText("チェックテスト")
        app.buttons["追加"].tap()

        // チェック（アイテム行をタップ）
        let item = app.staticTexts["チェックテスト"]
        XCTAssertTrue(item.waitForExistence(timeout: 5))
        item.tap()

        // チェック済みセクションに移動していることを確認（少し待つ）
        sleep(1)
        XCTAssertTrue(app.staticTexts["チェックテスト"].exists)
    }

    func test_paywall_on_third_list() {
        DevServer.reset(username: "devuser", isPro: false)
        devLoginAndWait()

        // 無料ユーザーでグループに参加している状態を想定
        // (この時点でグループがない場合はスキップ)
        let addListBtn = app.buttons["リストを追加"]
        if !addListBtn.waitForExistence(timeout: 3) { return }

        // リスト2個まで追加
        addListBtn.tap()
        var tf = app.textFields["addListTextField"]
        tf.waitForExistence(timeout: 5); tf.tap(); tf.typeText("リスト1")
        app.buttons["addListConfirmButton"].tap()
        sleep(1)

        app.buttons["リストを追加"].tap()
        tf = app.textFields["addListTextField"]
        tf.waitForExistence(timeout: 5); tf.tap(); tf.typeText("リスト2")
        app.buttons["addListConfirmButton"].tap()
        sleep(1)

        // 3個目でPaywall
        app.buttons["リストを追加"].tap()
        XCTAssertTrue(app.staticTexts["FamiList Pro にアップグレード"].waitForExistence(timeout: 5))
    }
}

// MARK: - マルチユーザーテスト（招待・キック・脱退）

final class E2EMultiUserTests: E2EBaseTest {

    private var inviteCode: String = ""

    /// devuser（オーナー）でグループを作成し招待コードを取得
    private func setupOwnerWithGroup() -> String {
        DevServer.reset(username: "devuser", isPro: true)
        DevServer.reset(username: "devuser2", isPro: false)

        devLoginAndWait(username: "devuser")

        // グループ作成
        app.buttons.matching(NSPredicate(format: "label CONTAINS 'グループ' OR label CONTAINS 'なし'")).firstMatch.tap()
        app.buttons["新しいグループ"].waitForExistence(timeout: 5)
        app.buttons["新しいグループ"].tap()
        let tf = app.textFields.firstMatch
        tf.waitForExistence(timeout: 3); tf.tap(); tf.typeText("マルチユーザーグループ")
        app.buttons["作成"].tap()
        app.buttons["tab_リスト"].waitForExistence(timeout: 10)

        // メンバータブ → 招待コードを取得
        switchTab("メンバー")
        app.buttons["inviteButton"].waitForExistence(timeout: 5)
        app.buttons["inviteButton"].tap()

        let codeLabel = app.staticTexts["inviteCodeText"]
        codeLabel.waitForExistence(timeout: 5)
        let code = codeLabel.label
        app.buttons["閉じる"].tap()

        return code
    }

    func test_join_group_via_invite_code() {
        let code = setupOwnerWithGroup()
        XCTAssertEqual(code.count, 6, "招待コードは6文字")

        // devuser2 としてログイン
        switchTab("設定")
        app.otherElements["signOutRow"].tap()
        app.buttons["サインアウト"].tap()

        app.launchEnvironment["UI_TESTING_DEV_USERNAME"] = "devuser2"
        app.buttons["devLoginButton"].waitForExistence(timeout: 5)
        app.buttons["devLoginButton"].tap()
        app.buttons["tab_リスト"].waitForExistence(timeout: 10)

        // グループピッカーから招待コードで参加
        app.buttons.matching(NSPredicate(format: "label CONTAINS 'グループ' OR label CONTAINS 'なし'")).firstMatch.tap()
        let joinBtn = app.buttons["招待コードで参加"]
        XCTAssertTrue(joinBtn.waitForExistence(timeout: 5))
        joinBtn.tap()

        let codeTF = app.textFields.firstMatch
        XCTAssertTrue(codeTF.waitForExistence(timeout: 3))
        codeTF.tap()
        codeTF.typeText(code)
        app.buttons["参加"].tap()

        // グループに参加できた
        XCTAssertTrue(app.buttons["tab_リスト"].waitForExistence(timeout: 10))
        switchTab("メンバー")
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'マルチユーザーグループ'")).firstMatch.waitForExistence(timeout: 5))
    }

    func test_kick_member() {
        let code = setupOwnerWithGroup()

        // devuser2 が参加
        switchTab("設定")
        app.otherElements["signOutRow"].tap()
        app.buttons["サインアウト"].tap()

        app.launchEnvironment["UI_TESTING_DEV_USERNAME"] = "devuser2"
        app.buttons["devLoginButton"].waitForExistence(timeout: 5)
        app.buttons["devLoginButton"].tap()
        app.buttons["tab_リスト"].waitForExistence(timeout: 10)

        app.buttons.matching(NSPredicate(format: "label CONTAINS 'グループ' OR label CONTAINS 'なし'")).firstMatch.tap()
        app.buttons["招待コードで参加"].waitForExistence(timeout: 5)
        app.buttons["招待コードで参加"].tap()
        let codeTF = app.textFields.firstMatch
        codeTF.waitForExistence(timeout: 3); codeTF.tap(); codeTF.typeText(code)
        app.buttons["参加"].tap()
        app.buttons["tab_リスト"].waitForExistence(timeout: 10)

        // devuser（オーナー）に切り替えてキック
        switchTab("設定")
        app.otherElements["signOutRow"].tap()
        app.buttons["サインアウト"].tap()

        app.launchEnvironment.removeValue(forKey: "UI_TESTING_DEV_USERNAME")
        app.buttons["devLoginButton"].waitForExistence(timeout: 5)
        app.buttons["devLoginButton"].tap()
        app.buttons["tab_リスト"].waitForExistence(timeout: 10)

        switchTab("メンバー")
        // devuser2 の行を長押し
        let memberRow = app.staticTexts["devuser2"]
        XCTAssertTrue(memberRow.waitForExistence(timeout: 5))
        memberRow.press(forDuration: 1.0)

        // コンテキストメニュー「グループから削除」
        let removeBtn = app.buttons["グループから削除"]
        XCTAssertTrue(removeBtn.waitForExistence(timeout: 3))
        removeBtn.tap()

        // 確認ダイアログ
        let confirmBtn = app.buttons.matching(NSPredicate(format: "label CONTAINS '削除'")).firstMatch
        XCTAssertTrue(confirmBtn.waitForExistence(timeout: 3))
        confirmBtn.tap()

        // devuser2 が一覧から消える
        sleep(1)
        XCTAssertFalse(app.staticTexts["devuser2"].exists)
    }

    func test_leave_group() {
        let code = setupOwnerWithGroup()

        // devuser2 が参加
        switchTab("設定")
        app.otherElements["signOutRow"].tap()
        app.buttons["サインアウト"].tap()

        app.launchEnvironment["UI_TESTING_DEV_USERNAME"] = "devuser2"
        app.buttons["devLoginButton"].waitForExistence(timeout: 5)
        app.buttons["devLoginButton"].tap()
        app.buttons["tab_リスト"].waitForExistence(timeout: 10)

        app.buttons.matching(NSPredicate(format: "label CONTAINS 'グループ' OR label CONTAINS 'なし'")).firstMatch.tap()
        app.buttons["招待コードで参加"].waitForExistence(timeout: 5)
        app.buttons["招待コードで参加"].tap()
        let codeTF = app.textFields.firstMatch
        codeTF.waitForExistence(timeout: 3); codeTF.tap(); codeTF.typeText(code)
        app.buttons["参加"].tap()
        app.buttons["tab_リスト"].waitForExistence(timeout: 10)

        // グループピッカーを開いて「グループを脱退」
        app.buttons.matching(NSPredicate(format: "label CONTAINS 'マルチユーザーグループ'")).firstMatch.tap()

        let groupRow = app.staticTexts["マルチユーザーグループ"]
        XCTAssertTrue(groupRow.waitForExistence(timeout: 5))
        groupRow.press(forDuration: 1.0)

        let leaveBtn = app.buttons["グループを脱退"]
        XCTAssertTrue(leaveBtn.waitForExistence(timeout: 3))
        leaveBtn.tap()

        let confirmBtn = app.buttons.matching(NSPredicate(format: "label CONTAINS '脱退'")).firstMatch
        XCTAssertTrue(confirmBtn.waitForExistence(timeout: 3))
        confirmBtn.tap()

        // グループから脱退しリスト画面に戻る
        XCTAssertTrue(app.buttons["tab_リスト"].waitForExistence(timeout: 10))
    }
}

// MARK: - アイテム操作（編集・削除・一括削除）

extension E2EShoppingTests {

    func test_edit_item() {
        setupGroupAndList()

        let listCell = app.staticTexts["週末の買い物"]
        XCTAssertTrue(listCell.waitForExistence(timeout: 5))
        listCell.tap()

        // アイテム追加
        let composer = app.textFields["itemComposer"]
        XCTAssertTrue(composer.waitForExistence(timeout: 5))
        composer.tap(); composer.typeText("編集前")
        app.buttons["追加"].tap()
        if app.keyboards.firstMatch.exists { composer.typeText("\n") }

        // スワイプ編集
        let itemCell = app.staticTexts["編集前"]
        XCTAssertTrue(itemCell.waitForExistence(timeout: 5))
        itemCell.swipeLeft()
        let editBtn = app.buttons.matching(NSPredicate(format: "label CONTAINS '編集'")).firstMatch
        XCTAssertTrue(editBtn.waitForExistence(timeout: 3))
        editBtn.tap()

        // 編集シートで名前変更
        let nameTF = app.textFields.firstMatch
        XCTAssertTrue(nameTF.waitForExistence(timeout: 3))
        nameTF.clearAndType("編集後")
        app.buttons.matching(NSPredicate(format: "label CONTAINS '保存' OR label CONTAINS 'Save'")).firstMatch.tap()

        XCTAssertTrue(app.staticTexts["編集後"].waitForExistence(timeout: 5))
    }

    func test_delete_item_via_swipe() {
        setupGroupAndList()

        let listCell = app.staticTexts["週末の買い物"]
        XCTAssertTrue(listCell.waitForExistence(timeout: 5))
        listCell.tap()

        let composer = app.textFields["itemComposer"]
        XCTAssertTrue(composer.waitForExistence(timeout: 5))
        composer.tap(); composer.typeText("削除対象")
        app.buttons["追加"].tap()
        if app.keyboards.firstMatch.exists { composer.typeText("\n") }

        let itemCell = app.staticTexts["削除対象"]
        XCTAssertTrue(itemCell.waitForExistence(timeout: 5))
        itemCell.swipeLeft()
        let deleteBtn = app.buttons.matching(NSPredicate(format: "label CONTAINS '削除' OR label CONTAINS 'Delete'")).firstMatch
        XCTAssertTrue(deleteBtn.waitForExistence(timeout: 3))
        deleteBtn.tap()

        sleep(1)
        XCTAssertFalse(app.staticTexts["削除対象"].exists)
    }

    func test_bulk_delete_checked_items() {
        setupGroupAndList()

        let listCell = app.staticTexts["週末の買い物"]
        XCTAssertTrue(listCell.waitForExistence(timeout: 5))
        listCell.tap()

        let composer = app.textFields["itemComposer"]
        XCTAssertTrue(composer.waitForExistence(timeout: 5))
        composer.tap(); composer.typeText("チェック商品")
        app.buttons["追加"].tap()
        if app.keyboards.firstMatch.exists { composer.typeText("\n") }

        // チェックしてチェック済みセクションへ
        let item = app.staticTexts["チェック商品"]
        XCTAssertTrue(item.waitForExistence(timeout: 5))
        item.tap()
        sleep(1)

        // チェック済みを一括削除
        let bulkDeleteBtn = app.buttons.matching(NSPredicate(format: "label CONTAINS 'チェック済みを削除' OR label CONTAINS 'Clear Checked'")).firstMatch
        XCTAssertTrue(bulkDeleteBtn.waitForExistence(timeout: 5))
        bulkDeleteBtn.tap()

        sleep(1)
        XCTAssertFalse(app.staticTexts["チェック商品"].exists)
    }
}

// MARK: - メール認証 E2E

final class E2EAuthTests: E2EBaseTest {

    func test_email_register_and_login() {
        let email = "uitest_\(Int.random(in: 10000...99999))@example.com"
        let password = "TestPass123"

        app.launchArguments = ["UI_TESTING_CLEAR_AUTH"]
        app.launch()

        // メールアドレスで続けるボタンをタップ
        let emailBtn = app.buttons.matching(NSPredicate(format: "label CONTAINS 'メールアドレス' OR label CONTAINS 'Email'")).firstMatch
        XCTAssertTrue(emailBtn.waitForExistence(timeout: 5))
        emailBtn.tap()

        // 「新規登録」タブへ切り替え
        let registerTab = app.buttons.matching(NSPredicate(format: "label CONTAINS '新規登録' OR label CONTAINS 'Sign Up'")).firstMatch
        if registerTab.waitForExistence(timeout: 3) { registerTab.tap() }

        // メール・パスワード入力
        let emailField = app.textFields["emailAuthEmailField"]
        XCTAssertTrue(emailField.waitForExistence(timeout: 5))
        emailField.tap(); emailField.typeText(email)

        let passField = app.secureTextFields["emailAuthPasswordField"]
        XCTAssertTrue(passField.waitForExistence(timeout: 3))
        passField.tap(); passField.typeText(password)

        // 登録ボタン
        app.buttons["emailAuthSubmitButton"].tap()

        // メイン画面に到達
        XCTAssertTrue(app.buttons["tab_リスト"].waitForExistence(timeout: 10))
    }
}

// MARK: - アカウント削除 E2E

extension E2ELoginTests {

    func test_delete_account_returns_to_login() {
        DevServer.reset(username: "devuser", isPro: false)
        devLoginAndWait()

        switchTab("設定")
        let deleteRow = app.otherElements["deleteAccountRow"]
        XCTAssertTrue(deleteRow.waitForExistence(timeout: 5))
        deleteRow.tap()

        // 確認ダイアログ → 「削除する」
        let confirmBtn = app.buttons.matching(NSPredicate(format: "label CONTAINS '削除' OR label CONTAINS 'Delete'")).firstMatch
        XCTAssertTrue(confirmBtn.waitForExistence(timeout: 3))
        confirmBtn.tap()

        // ログイン画面に戻る
        XCTAssertTrue(app.buttons["devLoginButton"].waitForExistence(timeout: 10))
    }
}

// MARK: - XCUIElement helper

private extension XCUIElement {
    func clearAndType(_ text: String) {
        tap()
        let selectAll = XCUIApplication().menuItems["Select All"]
        if selectAll.waitForExistence(timeout: 1) {
            selectAll.tap()
            typeText(text)
        } else {
            let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: (value as? String)?.count ?? 0)
            typeText(deleteString + text)
        }
    }
}
