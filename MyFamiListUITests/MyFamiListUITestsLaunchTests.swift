import XCTest

final class MyFamiListUITestsLaunchTests: XCTestCase {

    override class var runsForEachTargetApplicationUIConfiguration: Bool { true }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testLaunch() throws {
        let app = XCUIApplication()
        app.launchArguments = ["UI_TESTING_CLEAR_AUTH"]
        app.launch()

        let loginButton = app.buttons["メールアドレスで続ける"]
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(
            loginButton.waitForExistence(timeout: 5) || tabBar.waitForExistence(timeout: 5),
            "ログイン画面またはメイン画面が表示されること"
        )

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Launch Screen"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
