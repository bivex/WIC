//
//  WindowPositionTests.swift
//  WICTests
//
//  Tests for WindowPosition frame calculations
//

import XCTest
import AppKit
@testable import WIC

final class WindowPositionTests: XCTestCase {

    var mockScreen: MockNSScreen!

    override func setUp() {
        super.setUp()
        // Create a mock screen with a known frame
        mockScreen = MockNSScreen(frame: CGRect(x: 0, y: 0, width: 1920, height: 1080))
    }

    // MARK: - Half Screen Tests

    func testLeftHalfPosition() {
        let position = WindowPosition.leftHalf
        let frame = position.calculateFrame(for: mockScreen)

        XCTAssertEqual(frame.origin.x, 0)
        XCTAssertEqual(frame.origin.y, 0)
        XCTAssertEqual(frame.width, 960) // Half of 1920
        XCTAssertEqual(frame.height, 1080)
    }

    func testRightHalfPosition() {
        let position = WindowPosition.rightHalf
        let frame = position.calculateFrame(for: mockScreen)

        XCTAssertEqual(frame.origin.x, 960)
        XCTAssertEqual(frame.origin.y, 0)
        XCTAssertEqual(frame.width, 960)
        XCTAssertEqual(frame.height, 1080)
    }

    func testTopHalfPosition() {
        let position = WindowPosition.topHalf
        let frame = position.calculateFrame(for: mockScreen)

        XCTAssertEqual(frame.origin.x, 0)
        XCTAssertEqual(frame.origin.y, 540) // Half of height
        XCTAssertEqual(frame.width, 1920)
        XCTAssertEqual(frame.height, 540)
    }

    func testBottomHalfPosition() {
        let position = WindowPosition.bottomHalf
        let frame = position.calculateFrame(for: mockScreen)

        XCTAssertEqual(frame.origin.x, 0)
        XCTAssertEqual(frame.origin.y, 0)
        XCTAssertEqual(frame.width, 1920)
        XCTAssertEqual(frame.height, 540)
    }

    // MARK: - Quarter Screen Tests

    func testTopLeftQuarterPosition() {
        let position = WindowPosition.topLeftQuarter
        let frame = position.calculateFrame(for: mockScreen)

        XCTAssertEqual(frame.origin.x, 0)
        XCTAssertEqual(frame.origin.y, 540)
        XCTAssertEqual(frame.width, 960)
        XCTAssertEqual(frame.height, 540)
    }

    func testTopRightQuarterPosition() {
        let position = WindowPosition.topRightQuarter
        let frame = position.calculateFrame(for: mockScreen)

        XCTAssertEqual(frame.origin.x, 960)
        XCTAssertEqual(frame.origin.y, 540)
        XCTAssertEqual(frame.width, 960)
        XCTAssertEqual(frame.height, 540)
    }

    func testBottomLeftQuarterPosition() {
        let position = WindowPosition.bottomLeftQuarter
        let frame = position.calculateFrame(for: mockScreen)

        XCTAssertEqual(frame.origin.x, 0)
        XCTAssertEqual(frame.origin.y, 0)
        XCTAssertEqual(frame.width, 960)
        XCTAssertEqual(frame.height, 540)
    }

    func testBottomRightQuarterPosition() {
        let position = WindowPosition.bottomRightQuarter
        let frame = position.calculateFrame(for: mockScreen)

        XCTAssertEqual(frame.origin.x, 960)
        XCTAssertEqual(frame.origin.y, 0)
        XCTAssertEqual(frame.width, 960)
        XCTAssertEqual(frame.height, 540)
    }

    // MARK: - Third Screen Tests

    func testLeftThirdPosition() {
        let position = WindowPosition.leftThird
        let frame = position.calculateFrame(for: mockScreen)

        XCTAssertEqual(frame.origin.x, 0)
        XCTAssertEqual(frame.origin.y, 0)
        XCTAssertEqual(frame.width, 640) // 1920 / 3
        XCTAssertEqual(frame.height, 1080)
    }

    func testCenterThirdPosition() {
        let position = WindowPosition.centerThird
        let frame = position.calculateFrame(for: mockScreen)

        XCTAssertEqual(frame.origin.x, 640)
        XCTAssertEqual(frame.origin.y, 0)
        XCTAssertEqual(frame.width, 640)
        XCTAssertEqual(frame.height, 1080)
    }

    func testRightThirdPosition() {
        let position = WindowPosition.rightThird
        let frame = position.calculateFrame(for: mockScreen)

        XCTAssertEqual(frame.origin.x, 1280) // 1920 * 2 / 3
        XCTAssertEqual(frame.origin.y, 0)
        XCTAssertEqual(frame.width, 640)
        XCTAssertEqual(frame.height, 1080)
    }

    // MARK: - Two Thirds Tests

    func testLeftTwoThirdsPosition() {
        let position = WindowPosition.leftTwoThirds
        let frame = position.calculateFrame(for: mockScreen)

        XCTAssertEqual(frame.origin.x, 0)
        XCTAssertEqual(frame.origin.y, 0)
        XCTAssertEqual(frame.width, 1280) // 1920 * 2 / 3
        XCTAssertEqual(frame.height, 1080)
    }

    func testRightTwoThirdsPosition() {
        let position = WindowPosition.rightTwoThirds
        let frame = position.calculateFrame(for: mockScreen)

        XCTAssertEqual(frame.origin.x, 640)
        XCTAssertEqual(frame.origin.y, 0)
        XCTAssertEqual(frame.width, 1280)
        XCTAssertEqual(frame.height, 1080)
    }

    // MARK: - Center and Maximize Tests

    func testCenterPosition() {
        let position = WindowPosition.center
        let frame = position.calculateFrame(for: mockScreen)

        let expectedWidth = 1920 * 0.7
        let expectedHeight = 1080 * 0.7

        XCTAssertEqual(frame.width, expectedWidth, accuracy: 0.01)
        XCTAssertEqual(frame.height, expectedHeight, accuracy: 0.01)

        // Should be centered
        let expectedX = (1920 - expectedWidth) / 2
        let expectedY = (1080 - expectedHeight) / 2
        XCTAssertEqual(frame.origin.x, expectedX, accuracy: 0.01)
        XCTAssertEqual(frame.origin.y, expectedY, accuracy: 0.01)
    }

    func testMaximizePosition() {
        let position = WindowPosition.maximize
        let frame = position.calculateFrame(for: mockScreen)

        XCTAssertEqual(frame, mockScreen.visibleFrame)
    }

    // MARK: - Display Name Tests

    func testDisplayNames() {
        XCTAssertEqual(WindowPosition.leftHalf.displayName, "Левая половина")
        XCTAssertEqual(WindowPosition.rightHalf.displayName, "Правая половина")
        XCTAssertEqual(WindowPosition.topHalf.displayName, "Верхняя половина")
        XCTAssertEqual(WindowPosition.bottomHalf.displayName, "Нижняя половина")
        XCTAssertEqual(WindowPosition.center.displayName, "Центр")
        XCTAssertEqual(WindowPosition.maximize.displayName, "Максимизировать")
    }

    // MARK: - Identifiable Tests

    func testWindowPositionIds() {
        XCTAssertEqual(WindowPosition.leftHalf.id, "left_half")
        XCTAssertEqual(WindowPosition.rightHalf.id, "right_half")
        XCTAssertEqual(WindowPosition.topLeftQuarter.id, "top_left_quarter")
        XCTAssertEqual(WindowPosition.center.id, "center")
    }

    // MARK: - Non-Standard Screen Tests

    func testVerticalScreen() {
        // Test with a vertical screen (portrait orientation)
        let verticalScreen = MockNSScreen(frame: CGRect(x: 0, y: 0, width: 1080, height: 1920))

        let leftHalf = WindowPosition.leftHalf.calculateFrame(for: verticalScreen)
        XCTAssertEqual(leftHalf.width, 540)
        XCTAssertEqual(leftHalf.height, 1920)

        let topHalf = WindowPosition.topHalf.calculateFrame(for: verticalScreen)
        XCTAssertEqual(topHalf.width, 1080)
        XCTAssertEqual(topHalf.height, 960)
    }

    func testSmallScreen() {
        // Test with a smaller screen
        let smallScreen = MockNSScreen(frame: CGRect(x: 0, y: 0, width: 1280, height: 720))

        let leftHalf = WindowPosition.leftHalf.calculateFrame(for: smallScreen)
        XCTAssertEqual(leftHalf.width, 640)
        XCTAssertEqual(leftHalf.height, 720)
    }

    func testScreenWithOffset() {
        // Test with a screen that has an offset (multi-monitor setup)
        let offsetScreen = MockNSScreen(frame: CGRect(x: 1920, y: 0, width: 1920, height: 1080))

        let leftHalf = WindowPosition.leftHalf.calculateFrame(for: offsetScreen)
        XCTAssertEqual(leftHalf.origin.x, 1920)
        XCTAssertEqual(leftHalf.width, 960)
    }
}

// MARK: - Mock NSScreen

class MockNSScreen: NSScreen {
    private let mockFrame: CGRect

    init(frame: CGRect) {
        self.mockFrame = frame
        super.init()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var visibleFrame: CGRect {
        return mockFrame
    }

    override var frame: CGRect {
        return mockFrame
    }
}
