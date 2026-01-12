//
//  ModelsTests.swift
//  WICTests
//
//  Tests for various model types
//

import XCTest
import CoreGraphics
@testable import WIC

final class ModelsTests: XCTestCase {

    // MARK: - SnapSettings Tests

    func testSnapSettingsDefaultValues() {
        let settings = SnapSettings()

        XCTAssertTrue(settings.isEnabled)
        XCTAssertEqual(settings.snapThreshold, 20)
        XCTAssertEqual(settings.animationDuration, 0.2)
    }

    func testSnapSettingsCustomValues() {
        var settings = SnapSettings()
        settings.isEnabled = false
        settings.snapThreshold = 30
        settings.animationDuration = 0.5

        XCTAssertFalse(settings.isEnabled)
        XCTAssertEqual(settings.snapThreshold, 30)
        XCTAssertEqual(settings.animationDuration, 0.5)
    }

    // MARK: - DisplayInfo Tests

    func testDisplayInfoIdentifiable() {
        let display = DisplayInfo(
            id: 1,
            name: "Display 1",
            frame: CGRect(x: 0, y: 0, width: 1920, height: 1080),
            isVertical: false
        )

        XCTAssertEqual(display.id, 1)
        XCTAssertEqual(display.name, "Display 1")
        XCTAssertEqual(display.frame.width, 1920)
        XCTAssertEqual(display.frame.height, 1080)
        XCTAssertFalse(display.isVertical)
    }

    func testDisplayInfoVerticalDetection() {
        // Test horizontal display
        let horizontalDisplay = DisplayInfo(
            id: 1,
            name: "Horizontal",
            frame: CGRect(x: 0, y: 0, width: 1920, height: 1080),
            isVertical: false
        )
        XCTAssertFalse(horizontalDisplay.isVertical)

        // Test vertical display
        let verticalDisplay = DisplayInfo(
            id: 2,
            name: "Vertical",
            frame: CGRect(x: 0, y: 0, width: 1080, height: 1920),
            isVertical: true
        )
        XCTAssertTrue(verticalDisplay.isVertical)
    }

    // MARK: - AutoLayoutType Tests

    func testAutoLayoutTypeIds() {
        XCTAssertEqual(AutoLayoutType.grid.id, "grid")
        XCTAssertEqual(AutoLayoutType.horizontal.id, "horizontal")
        XCTAssertEqual(AutoLayoutType.vertical.id, "vertical")
        XCTAssertEqual(AutoLayoutType.cascade.id, "cascade")
        XCTAssertEqual(AutoLayoutType.fibonacci.id, "fibonacci")
        XCTAssertEqual(AutoLayoutType.focus.id, "focus")
    }

    func testAutoLayoutTypeDisplayNames() {
        XCTAssertEqual(AutoLayoutType.grid.displayName, "Сетка")
        XCTAssertEqual(AutoLayoutType.horizontal.displayName, "Горизонтально")
        XCTAssertEqual(AutoLayoutType.vertical.displayName, "Вертикально")
        XCTAssertEqual(AutoLayoutType.cascade.displayName, "Каскад")
        XCTAssertEqual(AutoLayoutType.fibonacci.displayName, "Фибоначчи")
        XCTAssertEqual(AutoLayoutType.focus.displayName, "Фокус")
    }

    func testAutoLayoutTypeDescriptions() {
        XCTAssertFalse(AutoLayoutType.grid.description.isEmpty)
        XCTAssertFalse(AutoLayoutType.horizontal.description.isEmpty)
        XCTAssertFalse(AutoLayoutType.vertical.description.isEmpty)
        XCTAssertFalse(AutoLayoutType.cascade.description.isEmpty)
        XCTAssertFalse(AutoLayoutType.fibonacci.description.isEmpty)
        XCTAssertFalse(AutoLayoutType.focus.description.isEmpty)
    }

    func testAutoLayoutTypeIconNames() {
        XCTAssertEqual(AutoLayoutType.grid.iconName, "square.grid.2x2")
        XCTAssertEqual(AutoLayoutType.horizontal.iconName, "rectangle.split.3x1")
        XCTAssertEqual(AutoLayoutType.vertical.iconName, "rectangle.split.1x2")
        XCTAssertEqual(AutoLayoutType.cascade.iconName, "square.stack.3d.up")
        XCTAssertEqual(AutoLayoutType.fibonacci.iconName, "square.grid.3x1.folder.badge.plus")
        XCTAssertEqual(AutoLayoutType.focus.iconName, "sidebar.left")
    }

    func testAutoLayoutTypeCaseIterable() {
        let allCases = AutoLayoutType.allCases
        XCTAssertEqual(allCases.count, 14) // 6 базовых + 8 умных режимов

        // Базовые режимы
        XCTAssertTrue(allCases.contains(.grid))
        XCTAssertTrue(allCases.contains(.horizontal))
        XCTAssertTrue(allCases.contains(.vertical))
        XCTAssertTrue(allCases.contains(.cascade))
        XCTAssertTrue(allCases.contains(.fibonacci))
        XCTAssertTrue(allCases.contains(.focus))

        // Умные режимы
        XCTAssertTrue(allCases.contains(.readingMode))
        XCTAssertTrue(allCases.contains(.codingMode))
        XCTAssertTrue(allCases.contains(.designMode))
        XCTAssertTrue(allCases.contains(.communicationMode))
        XCTAssertTrue(allCases.contains(.researchMode))
        XCTAssertTrue(allCases.contains(.presentationMode))
        XCTAssertTrue(allCases.contains(.multiTaskMode))
        XCTAssertTrue(allCases.contains(.ultraWideMode))
    }

    // MARK: - WindowInfo Tests

    func testWindowInfoStructure() {
        let mockElement = AXUIElementCreateSystemWide()
        let windowInfo = WindowInfo(
            element: mockElement,
            title: "Test Window",
            frame: CGRect(x: 100, y: 100, width: 800, height: 600)
        )

        XCTAssertEqual(windowInfo.title, "Test Window")
        XCTAssertEqual(windowInfo.frame.origin.x, 100)
        XCTAssertEqual(windowInfo.frame.origin.y, 100)
        XCTAssertEqual(windowInfo.frame.width, 800)
        XCTAssertEqual(windowInfo.frame.height, 600)
    }
}
