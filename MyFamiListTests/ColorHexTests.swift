import XCTest
import SwiftUI
import UIKit
@testable import MyFamiList

final class ColorHexTests: XCTestCase {

    private func rgba(_ color: Color) -> (r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat) {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        UIColor(color).getRed(&r, green: &g, blue: &b, alpha: &a)
        return (r, g, b, a)
    }

    // MARK: - 6-digit hex

    func test_6digit_red() {
        let c = rgba(Color(hex: "#FF0000"))
        XCTAssertEqual(c.r, 1.0, accuracy: 0.01)
        XCTAssertEqual(c.g, 0.0, accuracy: 0.01)
        XCTAssertEqual(c.b, 0.0, accuracy: 0.01)
        XCTAssertEqual(c.a, 1.0, accuracy: 0.01)
    }

    func test_6digit_blue() {
        let c = rgba(Color(hex: "#0000FF"))
        XCTAssertEqual(c.r, 0.0, accuracy: 0.01)
        XCTAssertEqual(c.g, 0.0, accuracy: 0.01)
        XCTAssertEqual(c.b, 1.0, accuracy: 0.01)
    }

    func test_6digit_without_hash_prefix() {
        let c = rgba(Color(hex: "00FF00"))
        XCTAssertEqual(c.g, 1.0, accuracy: 0.01)
        XCTAssertEqual(c.r, 0.0, accuracy: 0.01)
        XCTAssertEqual(c.b, 0.0, accuracy: 0.01)
    }

    func test_6digit_app_green() {
        // #16A368 — アプリ内で使用されているカラー
        let c = rgba(Color(hex: "#16A368"))
        XCTAssertEqual(c.r, Double(0x16) / 255.0, accuracy: 0.01)
        XCTAssertEqual(c.g, Double(0xA3) / 255.0, accuracy: 0.01)
        XCTAssertEqual(c.b, Double(0x68) / 255.0, accuracy: 0.01)
    }

    // MARK: - 3-digit hex

    func test_3digit_red() {
        let c = rgba(Color(hex: "#F00"))
        XCTAssertEqual(c.r, 1.0, accuracy: 0.01)
        XCTAssertEqual(c.g, 0.0, accuracy: 0.01)
        XCTAssertEqual(c.b, 0.0, accuracy: 0.01)
    }

    func test_3digit_white() {
        let c = rgba(Color(hex: "#FFF"))
        XCTAssertEqual(c.r, 1.0, accuracy: 0.01)
        XCTAssertEqual(c.g, 1.0, accuracy: 0.01)
        XCTAssertEqual(c.b, 1.0, accuracy: 0.01)
    }

    // MARK: - 8-digit hex (with alpha)

    func test_8digit_semi_transparent_red() {
        let c = rgba(Color(hex: "#80FF0000"))
        XCTAssertEqual(c.r, 1.0, accuracy: 0.01)
        XCTAssertEqual(c.g, 0.0, accuracy: 0.01)
        XCTAssertEqual(c.b, 0.0, accuracy: 0.01)
        XCTAssertEqual(c.a, Double(0x80) / 255.0, accuracy: 0.01)
    }

    func test_8digit_fully_transparent() {
        let c = rgba(Color(hex: "#00FFFFFF"))
        XCTAssertEqual(c.a, 0.0, accuracy: 0.01)
    }

    // MARK: - invalid input

    func test_invalid_hex_string_returns_black() {
        let c = rgba(Color(hex: "INVALID"))
        XCTAssertEqual(c.r, 0.0, accuracy: 0.01)
        XCTAssertEqual(c.g, 0.0, accuracy: 0.01)
        XCTAssertEqual(c.b, 0.0, accuracy: 0.01)
    }

    func test_empty_string_returns_black() {
        let c = rgba(Color(hex: ""))
        XCTAssertEqual(c.r, 0.0, accuracy: 0.01)
        XCTAssertEqual(c.g, 0.0, accuracy: 0.01)
        XCTAssertEqual(c.b, 0.0, accuracy: 0.01)
    }
}
