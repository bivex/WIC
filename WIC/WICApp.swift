//
//  WICApp.swift
//  WIC - Window Manager для macOS
//
//  Точка входа приложения
//

import SwiftUI
import AppKit

@main
struct WICApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var windowManager = WindowManager.shared
    @StateObject private var hotkeyManager = HotkeyManager.shared
    
    var body: some Scene {
        // Приложение работает из статус-бара, поэтому основное окно не нужно
        Settings {
            SettingsView()
                .environmentObject(windowManager)
                .environmentObject(hotkeyManager)
        }
    }
}

// MARK: - App Delegate
class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    var statusBarItem: NSStatusItem?
    private var statusBarMenu: NSMenu?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        autoreleasepool {
            Logger.shared.info("Application launching...")
            let launchTimer = Logger.shared.startOperation("Application Launch")
            
            // Скрыть иконку в Dock
            Logger.shared.debug("Setting activation policy to accessory")
            NSApp.setActivationPolicy(.accessory)
            
            // Создать статус-бар меню (отложенная инициализация)
            setupStatusBarItem()
            
            // Проверить и запросить разрешения Accessibility
            Logger.shared.debug("Checking Accessibility permissions")
            checkAccessibilityPermissions()
            
            // Инициализировать менеджеры
            Logger.shared.info("Initializing managers...")
            _ = WindowManager.shared
            _ = HotkeyManager.shared
            
            launchTimer.end()
            Logger.shared.info("Application launch complete")
        }
    }
    
    private func setupStatusBarItem() {
        statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        
        if let button = statusBarItem?.button {
            // Использовать SF Symbol для иконки
            let image = NSImage(systemSymbolName: "rectangle.split.3x3", accessibilityDescription: "WIC")
            image?.isTemplate = true
            button.image = image
            // Оптимизация: использовать action вместо menu для ленивой загрузки
            button.target = self
            button.action = #selector(statusBarButtonClicked)
        }
    }
    
    @objc private func statusBarButtonClicked() {
        autoreleasepool {
            if statusBarMenu == nil {
                statusBarMenu = createMenu()
                statusBarMenu?.delegate = self
            }
            statusBarItem?.menu = statusBarMenu
            statusBarItem?.button?.performClick(nil)
        }
    }
    
    // Очистить меню после закрытия для экономии памяти
    func menuDidClose(_ menu: NSMenu) {
        autoreleasepool {
            // Удалить ссылку на меню после закрытия
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                self?.statusBarItem?.menu = nil
            }
        }
    }
    

    
    // Создание основного меню (вызывается лениво)
    private func createMenu() -> NSMenu {
        let menu = NSMenu()
        menu.autoenablesItems = false
        menu.minimumWidth = 180
        
        // Только самые используемые пункты
        let settingsItem = NSMenuItem(title: "Настройки", action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)
        menu.addItem(NSMenuItem.separator())
        
        // Быстрые действия
        addMenuItem(to: menu, title: "← Лево", action: #selector(snapLeft))
        addMenuItem(to: menu, title: "→ Право", action: #selector(snapRight))
        addMenuItem(to: menu, title: "↑ Верх", action: #selector(snapTop))
        addMenuItem(to: menu, title: "↓ Низ", action: #selector(snapBottom))
        menu.addItem(NSMenuItem.separator())
        
        addMenuItem(to: menu, title: "◯ Центр", action: #selector(center))
        addMenuItem(to: menu, title: "◻ Макс", action: #selector(maximize))
        menu.addItem(NSMenuItem.separator())
        
        // Автолайаут - плоский список (без submenu для снижения overhead)
        addMenuItem(to: menu, title: "⚏ Сетка", action: #selector(applyGridLayout))
        addMenuItem(to: menu, title: "⚍ Горизонт", action: #selector(applyHorizontalLayout))
        addMenuItem(to: menu, title: "⚎ Вертикаль", action: #selector(applyVerticalLayout))
        menu.addItem(NSMenuItem.separator())
        
        let quitItem = NSMenuItem(title: "Выйти", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        
        return menu
    }
    
    private func addMenuItem(to menu: NSMenu, title: String, action: Selector) {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: "")
        item.target = self
        menu.addItem(item)
    }
    
    @objc private func openSettings() {
        Logger.shared.info("Opening settings window...")
        NSApp.activate(ignoringOtherApps: true)
        
        // Для SwiftUI Settings используем селектор preferences
        let result = NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
        Logger.shared.debug("Settings action result: \(result)")
        
        // Альтернативный способ - симулировать нажатие Cmd+,
        if !result {
            Logger.shared.debug("Trying alternative method with keyboard shortcut")
            let source = CGEventSource(stateID: .hidSystemState)
            
            // Cmd + ,
            if let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 0x2B, keyDown: true),
               let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 0x2B, keyDown: false) {
                keyDown.flags = .maskCommand
                keyUp.flags = .maskCommand
                keyDown.post(tap: .cghidEventTap)
                keyUp.post(tap: .cghidEventTap)
                Logger.shared.debug("Keyboard shortcut sent")
            }
        }
    }
    
    @objc private func snapLeft() {
        autoreleasepool {
            #if DEBUG
            Logger.shared.info("User action: Snap left")
            #endif
            WindowManager.shared.snapWindow(to: .leftHalf)
        }
    }
    
    @objc private func snapRight() {
        autoreleasepool {
            #if DEBUG
            Logger.shared.info("User action: Snap right")
            #endif
            WindowManager.shared.snapWindow(to: .rightHalf)
        }
    }
    
    @objc private func snapTop() {
        autoreleasepool {
            #if DEBUG
            Logger.shared.info("User action: Snap top")
            #endif
            WindowManager.shared.snapWindow(to: .topHalf)
        }
    }
    
    @objc private func snapBottom() {
        autoreleasepool {
            #if DEBUG
            Logger.shared.info("User action: Snap bottom")
            #endif
            WindowManager.shared.snapWindow(to: .bottomHalf)
        }
    }
    
    @objc private func center() {
        WindowManager.shared.centerWindow()
    }
    
    @objc private func maximize() {
        WindowManager.shared.maximizeWindow()
    }
    
    @objc private func applyGridLayout() {
        autoreleasepool {
            #if DEBUG
            Logger.shared.info("User action: Apply grid layout")
            #endif
            WindowManager.shared.applyAutoLayout(.grid)
        }
    }
    
    @objc private func applyHorizontalLayout() {
        autoreleasepool {
            #if DEBUG
            Logger.shared.info("User action: Apply horizontal layout")
            #endif
            WindowManager.shared.applyAutoLayout(.horizontal)
        }
    }
    
    @objc private func applyVerticalLayout() {
        autoreleasepool {
            #if DEBUG
            Logger.shared.info("User action: Apply vertical layout")
            #endif
            WindowManager.shared.applyAutoLayout(.vertical)
        }
    }
    
    @objc private func applyCascadeLayout() {
        autoreleasepool {
            #if DEBUG
            Logger.shared.info("User action: Apply cascade layout")
            #endif
            WindowManager.shared.applyAutoLayout(.cascade)
        }
    }
    
    @objc private func applyFibonacciLayout() {
        autoreleasepool {
            #if DEBUG
            Logger.shared.info("User action: Apply fibonacci layout")
            #endif
            WindowManager.shared.applyAutoLayout(.fibonacci)
        }
    }
    
    @objc private func applyFocusLayout() {
        autoreleasepool {
            #if DEBUG
            Logger.shared.info("User action: Apply focus layout")
            #endif
            WindowManager.shared.applyAutoLayout(.focus)
        }
    }
    
    @objc private func quit() {
        NSApplication.shared.terminate(nil)
    }
    
    private func checkAccessibilityPermissions() {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        let accessibilityEnabled = AXIsProcessTrustedWithOptions(options)
        
        if !accessibilityEnabled {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.showAccessibilityAlert()
            }
        }
    }
    
    private func showAccessibilityAlert() {
        let alert = NSAlert()
        alert.messageText = "Требуется разрешение Accessibility"
        alert.informativeText = "WIC необходим доступ к Accessibility для управления окнами других приложений. Пожалуйста, предоставьте разрешение в Системных настройках > Конфиденциальность и безопасность > Accessibility."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Открыть Системные настройки")
        alert.addButton(withTitle: "Позже")
        
        if alert.runModal() == .alertFirstButtonReturn {
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                NSWorkspace.shared.open(url)
            }
        }
    }
}
