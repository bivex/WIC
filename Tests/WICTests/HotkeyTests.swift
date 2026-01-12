//
//  HotkeyTests.swift
//  WICTests
//
//  Tests for HotkeyBinding and KeyModifiers
//

import XCTest
import Carbon
@testable import WIC

final class HotkeyTests: XCTestCase {

    // MARK: - KeyModifiers Tests

    func testKeyModifiersRawValues() {
        XCTAssertEqual(KeyModifiers.command.rawValue, 1 << 0)
        XCTAssertEqual(KeyModifiers.option.rawValue, 1 << 1)
        XCTAssertEqual(KeyModifiers.control.rawValue, 1 << 2)
        XCTAssertEqual(KeyModifiers.shift.rawValue, 1 << 3)
    }

    func testKeyModifiersSingleDisplayString() {
        XCTAssertEqual(KeyModifiers.command.displayString, "⌘")
        XCTAssertEqual(KeyModifiers.option.displayString, "⌥")
        XCTAssertEqual(KeyModifiers.control.displayString, "⌃")
        XCTAssertEqual(KeyModifiers.shift.displayString, "⇧")
    }

    func testKeyModifiersCombinedDisplayString() {
        let commandOption: KeyModifiers = [.command, .option]
        let displayString = commandOption.displayString
        XCTAssertTrue(displayString.contains("⌘"))
        XCTAssertTrue(displayString.contains("⌥"))

        let allModifiers: KeyModifiers = [.control, .option, .shift, .command]
        let allDisplay = allModifiers.displayString
        XCTAssertEqual(allDisplay, "⌃⌥⇧⌘") // Order: control, option, shift, command
    }

    func testKeyModifiersOptionSet() {
        var modifiers = KeyModifiers.command
        modifiers.insert(.option)

        XCTAssertTrue(modifiers.contains(.command))
        XCTAssertTrue(modifiers.contains(.option))
        XCTAssertFalse(modifiers.contains(.control))

        modifiers.remove(.command)
        XCTAssertFalse(modifiers.contains(.command))
        XCTAssertTrue(modifiers.contains(.option))
    }

    func testKeyModifiersCodable() throws {
        let modifiers: KeyModifiers = [.command, .option]

        // Encode
        let encoder = JSONEncoder()
        let data = try encoder.encode(modifiers)

        // Decode
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(KeyModifiers.self, from: data)

        XCTAssertEqual(decoded, modifiers)
        XCTAssertTrue(decoded.contains(.command))
        XCTAssertTrue(decoded.contains(.option))
    }

    // MARK: - HotkeyBinding Tests

    func testHotkeyBindingInitialization() {
        var actionCalled = false
        let binding = HotkeyBinding(
            id: 1,
            name: "Test Hotkey",
            keyCode: UInt16(kVK_LeftArrow),
            modifiers: [.command, .option],
            action: { actionCalled = true }
        )

        XCTAssertEqual(binding.id, 1)
        XCTAssertEqual(binding.name, "Test Hotkey")
        XCTAssertEqual(binding.keyCode, UInt16(kVK_LeftArrow))
        XCTAssertTrue(binding.modifiers.contains(.command))
        XCTAssertTrue(binding.modifiers.contains(.option))
        XCTAssertTrue(binding.isEnabled)

        // Test action
        XCTAssertFalse(actionCalled)
        binding.action()
        XCTAssertTrue(actionCalled)
    }

    func testHotkeyBindingIdentifiable() {
        let binding = HotkeyBinding(
            id: 42,
            name: "Test",
            keyCode: 0,
            modifiers: [],
            action: {}
        )

        XCTAssertEqual(binding.id, 42)
    }

    func testHotkeyBindingCodable() throws {
        let binding = HotkeyBinding(
            id: 1,
            name: "Left Half",
            keyCode: UInt16(kVK_LeftArrow),
            modifiers: [.command, .option],
            action: {}
        )

        // Encode
        let encoder = JSONEncoder()
        let data = try encoder.encode(binding)

        // Decode
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(HotkeyBinding.self, from: data)

        XCTAssertEqual(decoded.id, binding.id)
        XCTAssertEqual(decoded.name, binding.name)
        XCTAssertEqual(decoded.keyCode, binding.keyCode)
        XCTAssertEqual(decoded.modifiers, binding.modifiers)
        XCTAssertEqual(decoded.isEnabled, binding.isEnabled)
        // Note: action is not encoded/decoded
    }

    func testHotkeyBindingIsEnabled() {
        var binding = HotkeyBinding(
            id: 1,
            name: "Test",
            keyCode: 0,
            modifiers: [],
            action: {}
        )

        XCTAssertTrue(binding.isEnabled)

        binding.isEnabled = false
        XCTAssertFalse(binding.isEnabled)

        binding.isEnabled = true
        XCTAssertTrue(binding.isEnabled)
    }

    func testHotkeyBindingMutability() {
        var binding = HotkeyBinding(
            id: 1,
            name: "Original Name",
            keyCode: UInt16(kVK_LeftArrow),
            modifiers: [.command],
            action: {}
        )

        binding.name = "New Name"
        binding.keyCode = UInt16(kVK_RightArrow)
        binding.modifiers = [.option]
        binding.isEnabled = false

        XCTAssertEqual(binding.name, "New Name")
        XCTAssertEqual(binding.keyCode, UInt16(kVK_RightArrow))
        XCTAssertTrue(binding.modifiers.contains(.option))
        XCTAssertFalse(binding.modifiers.contains(.command))
        XCTAssertFalse(binding.isEnabled)
    }

    func testMultipleHotkeyBindings() {
        var count = 0

        let binding1 = HotkeyBinding(
            id: 1,
            name: "Hotkey 1",
            keyCode: UInt16(kVK_LeftArrow),
            modifiers: [.command],
            action: { count += 1 }
        )

        let binding2 = HotkeyBinding(
            id: 2,
            name: "Hotkey 2",
            keyCode: UInt16(kVK_RightArrow),
            modifiers: [.option],
            action: { count += 10 }
        )

        XCTAssertEqual(count, 0)

        binding1.action()
        XCTAssertEqual(count, 1)

        binding2.action()
        XCTAssertEqual(count, 11)

        binding1.action()
        XCTAssertEqual(count, 12)
    }

    // MARK: - Edge Cases

    func testEmptyModifiers() {
        let binding = HotkeyBinding(
            id: 1,
            name: "No Modifiers",
            keyCode: UInt16(kVK_Return),
            modifiers: [],
            action: {}
        )

        XCTAssertTrue(binding.modifiers.isEmpty)
        XCTAssertEqual(binding.modifiers.displayString, "")
    }

    func testAllModifiersCombined() {
        let allModifiers: KeyModifiers = [.control, .option, .shift, .command]
        let binding = HotkeyBinding(
            id: 1,
            name: "All Modifiers",
            keyCode: UInt16(kVK_ANSI_A),
            modifiers: allModifiers,
            action: {}
        )

        XCTAssertTrue(binding.modifiers.contains(KeyModifiers.control))
        XCTAssertTrue(binding.modifiers.contains(KeyModifiers.option))
        XCTAssertTrue(binding.modifiers.contains(KeyModifiers.shift))
        XCTAssertTrue(binding.modifiers.contains(KeyModifiers.command))
    }

    func testKeyCodeVariety() {
        let arrowKeys = [
            UInt16(kVK_LeftArrow),
            UInt16(kVK_RightArrow),
            UInt16(kVK_UpArrow),
            UInt16(kVK_DownArrow)
        ]

        for (index, keyCode) in arrowKeys.enumerated() {
            let binding = HotkeyBinding(
                id: index,
                name: "Arrow \(index)",
                keyCode: keyCode,
                modifiers: [.command],
                action: {}
            )
            XCTAssertEqual(binding.keyCode, keyCode)
        }
    }
}
