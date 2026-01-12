//
//  HotkeyManager.swift
//  WIC
//
//  Менеджер для управления глобальными горячими клавишами
//

import Foundation
import AppKit
import Carbon

class HotkeyManager: ObservableObject {
    static let shared = HotkeyManager()
    
    @Published var hotkeys: [HotkeyBinding] = []
    private var eventHandlers: [UInt32: EventHandlerRef] = [:]
    private var registeredHotkeys: [UInt32: EventHotKeyRef] = [:]
    
    private init() {
        setupDefaultHotkeys()
        registerAllHotkeys()
    }
    
    deinit {
        unregisterAllHotkeys()
    }
    
    // MARK: - Default Hotkeys Setup
    
    private func setupDefaultHotkeys() {
        hotkeys = [
            // Половины экрана
            HotkeyBinding(
                id: 1,
                name: "Левая половина",
                keyCode: UInt16(kVK_LeftArrow),
                modifiers: [.command, .option],
                action: { WindowManager.shared.snapWindow(to: .leftHalf) }
            ),
            HotkeyBinding(
                id: 2,
                name: "Правая половина",
                keyCode: UInt16(kVK_RightArrow),
                modifiers: [.command, .option],
                action: { WindowManager.shared.snapWindow(to: .rightHalf) }
            ),
            HotkeyBinding(
                id: 3,
                name: "Верхняя половина",
                keyCode: UInt16(kVK_UpArrow),
                modifiers: [.command, .option],
                action: { WindowManager.shared.snapWindow(to: .topHalf) }
            ),
            HotkeyBinding(
                id: 4,
                name: "Нижняя половина",
                keyCode: UInt16(kVK_DownArrow),
                modifiers: [.command, .option],
                action: { WindowManager.shared.snapWindow(to: .bottomHalf) }
            ),
            
            // Четверти экрана
            HotkeyBinding(
                id: 5,
                name: "Левая верхняя четверть",
                keyCode: UInt16(kVK_UpArrow),
                modifiers: [.command, .control],
                action: { WindowManager.shared.snapWindow(to: .topLeftQuarter) }
            ),
            HotkeyBinding(
                id: 6,
                name: "Правая верхняя четверть",
                keyCode: UInt16(kVK_ANSI_U),
                modifiers: [.command, .control, .option],
                action: { WindowManager.shared.snapWindow(to: .topRightQuarter) }
            ),
            HotkeyBinding(
                id: 7,
                name: "Левая нижняя четверть",
                keyCode: UInt16(kVK_ANSI_J),
                modifiers: [.command, .control, .option],
                action: { WindowManager.shared.snapWindow(to: .bottomLeftQuarter) }
            ),
            HotkeyBinding(
                id: 8,
                name: "Правая нижняя четверть",
                keyCode: UInt16(kVK_ANSI_K),
                modifiers: [.command, .control, .option],
                action: { WindowManager.shared.snapWindow(to: .bottomRightQuarter) }
            ),
            
            // Трети экрана
            HotkeyBinding(
                id: 9,
                name: "Левая треть",
                keyCode: UInt16(kVK_ANSI_D),
                modifiers: [.command, .option],
                action: { WindowManager.shared.snapWindow(to: .leftThird) }
            ),
            HotkeyBinding(
                id: 10,
                name: "Центральная треть",
                keyCode: UInt16(kVK_ANSI_F),
                modifiers: [.command, .option],
                action: { WindowManager.shared.snapWindow(to: .centerThird) }
            ),
            HotkeyBinding(
                id: 11,
                name: "Правая треть",
                keyCode: UInt16(kVK_ANSI_G),
                modifiers: [.command, .option],
                action: { WindowManager.shared.snapWindow(to: .rightThird) }
            ),
            
            // Две трети экрана
            HotkeyBinding(
                id: 12,
                name: "Левые две трети",
                keyCode: UInt16(kVK_ANSI_E),
                modifiers: [.command, .option],
                action: { WindowManager.shared.snapWindow(to: .leftTwoThirds) }
            ),
            HotkeyBinding(
                id: 13,
                name: "Правые две трети",
                keyCode: UInt16(kVK_ANSI_T),
                modifiers: [.command, .option],
                action: { WindowManager.shared.snapWindow(to: .rightTwoThirds) }
            ),
            
            // Центр и максимизация
            HotkeyBinding(
                id: 14,
                name: "Центрировать",
                keyCode: UInt16(kVK_ANSI_C),
                modifiers: [.command, .option],
                action: { WindowManager.shared.centerWindow() }
            ),
            HotkeyBinding(
                id: 15,
                name: "Максимизировать",
                keyCode: UInt16(kVK_Return),
                modifiers: [.command, .option],
                action: { WindowManager.shared.maximizeWindow() }
            ),
        ]
    }
    
    // MARK: - Hotkey Registration
    
    private func registerAllHotkeys() {
        for hotkey in hotkeys where hotkey.isEnabled {
            registerHotkey(hotkey)
        }
    }
    
    private func registerHotkey(_ hotkey: HotkeyBinding) {
        let hotkeyID = EventHotKeyID(
            signature: OSType(hotkey.id),
            id: UInt32(hotkey.id)
        )
        
        var eventHotkey: EventHotKeyRef?
        var eventSpec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        
        // Конвертировать модификаторы
        var carbonModifiers: UInt32 = 0
        if hotkey.modifiers.contains(.command) { carbonModifiers |= UInt32(cmdKey) }
        if hotkey.modifiers.contains(.option) { carbonModifiers |= UInt32(optionKey) }
        if hotkey.modifiers.contains(.control) { carbonModifiers |= UInt32(controlKey) }
        if hotkey.modifiers.contains(.shift) { carbonModifiers |= UInt32(shiftKey) }
        
        let status = RegisterEventHotKey(
            UInt32(hotkey.keyCode),
            carbonModifiers,
            hotkeyID,
            GetEventDispatcherTarget(),
            0,
            &eventHotkey
        )
        
        if status == noErr, let eventHotkey = eventHotkey {
            registeredHotkeys[UInt32(hotkey.id)] = eventHotkey
            
            // Создать обработчик события
            var handler: EventHandlerRef?
            let context = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
            
            InstallEventHandler(
                GetEventDispatcherTarget(),
                { (_, event, userData) -> OSStatus in
                    guard let userData = userData else { return OSStatus(eventNotHandledErr) }
                    let manager = Unmanaged<HotkeyManager>.fromOpaque(userData).takeUnretainedValue()
                    
                    var hotkeyID = EventHotKeyID()
                    GetEventParameter(
                        event,
                        EventParamName(kEventParamDirectObject),
                        EventParamType(typeEventHotKeyID),
                        nil,
                        MemoryLayout<EventHotKeyID>.size,
                        nil,
                        &hotkeyID
                    )
                    
                    // Найти и выполнить действие
                    if let binding = manager.hotkeys.first(where: { $0.id == Int(hotkeyID.id) }) {
                        DispatchQueue.main.async {
                            binding.action()
                        }
                    }
                    
                    return noErr
                },
                1,
                &eventSpec,
                context,
                &handler
            )
            
            if let handler = handler {
                eventHandlers[UInt32(hotkey.id)] = handler
            }
        }
    }
    
    private func unregisterAllHotkeys() {
        for (_, hotkey) in registeredHotkeys {
            UnregisterEventHotKey(hotkey)
        }
        registeredHotkeys.removeAll()
        
        for (_, handler) in eventHandlers {
            RemoveEventHandler(handler)
        }
        eventHandlers.removeAll()
    }
    
    // MARK: - Public Methods
    
    func updateHotkey(_ hotkey: HotkeyBinding) {
        if let index = hotkeys.firstIndex(where: { $0.id == hotkey.id }) {
            // Удалить старую регистрацию
            let hotkeyKey = UInt32(hotkey.id)
            if let eventHotkey = registeredHotkeys[hotkeyKey] {
                UnregisterEventHotKey(eventHotkey)
                registeredHotkeys.removeValue(forKey: hotkeyKey)
            }
            if let handler = eventHandlers[hotkeyKey] {
                RemoveEventHandler(handler)
                eventHandlers.removeValue(forKey: hotkeyKey)
            }
            
            // Обновить и перерегистрировать
            hotkeys[index] = hotkey
            if hotkey.isEnabled {
                registerHotkey(hotkey)
            }
        }
    }
    
    func toggleHotkey(_ id: Int) {
        guard let index = hotkeys.firstIndex(where: { $0.id == id }) else { return }
        var hotkey = hotkeys[index]
        hotkey.isEnabled.toggle()
        updateHotkey(hotkey)
    }
}

// MARK: - Hotkey Binding Model

struct HotkeyBinding: Identifiable, Codable {
    let id: Int
    var name: String
    var keyCode: UInt16
    var modifiers: KeyModifiers
    var isEnabled: Bool = true
    
    // Action не сохраняется, нужно переинициализировать при загрузке
    var action: () -> Void = {}
    
    enum CodingKeys: String, CodingKey {
        case id, name, keyCode, modifiers, isEnabled
    }
    
    init(id: Int, name: String, keyCode: UInt16, modifiers: KeyModifiers, action: @escaping () -> Void) {
        self.id = id
        self.name = name
        self.keyCode = keyCode
        self.modifiers = modifiers
        self.action = action
    }
}

// MARK: - Key Modifiers

struct KeyModifiers: OptionSet, Codable {
    let rawValue: Int
    
    static let command = KeyModifiers(rawValue: 1 << 0)
    static let option = KeyModifiers(rawValue: 1 << 1)
    static let control = KeyModifiers(rawValue: 1 << 2)
    static let shift = KeyModifiers(rawValue: 1 << 3)
    
    var displayString: String {
        var components: [String] = []
        if contains(.control) { components.append("⌃") }
        if contains(.option) { components.append("⌥") }
        if contains(.shift) { components.append("⇧") }
        if contains(.command) { components.append("⌘") }
        return components.joined()
    }
}
