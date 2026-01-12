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
class AppDelegate: NSObject, NSApplicationDelegate {
    var statusBarItem: NSStatusItem?
    private var _statusBarMenu: NSMenu?
    private var _autoLayoutSubmenu: NSMenu?
    
    // Lazy menu creation для уменьшения overhead
    private var statusBarMenu: NSMenu {
        if _statusBarMenu == nil {
            _statusBarMenu = createMenu()
        }
        return _statusBarMenu!
    }
    
    // Lazy submenu creation
    private var autoLayoutSubmenu: NSMenu {
        if _autoLayoutSubmenu == nil {
            _autoLayoutSubmenu = createAutoLayoutMenu()
        }
        return _autoLayoutSubmenu!
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        Logger.shared.info("Application launching...")
        let launchTimer = Logger.shared.startOperation("Application Launch")
        
        // Скрыть иконку в Dock
        Logger.shared.debug("Setting activation policy to accessory")
        NSApp.setActivationPolicy(.accessory)
        
        // Создать статус-бар меню
        let menuTimer = Logger.shared.startOperation("Status Bar Setup")
        setupStatusBarItem()
        menuTimer.end()
        
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
    
    private func setupStatusBarItem() {
        statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusBarItem?.button {
            // Использовать SF Symbol для иконки
            button.image = NSImage(systemSymbolName: "rectangle.split.3x3", accessibilityDescription: "WIC")
            button.image?.isTemplate = true
        }
        
        // Меню создастся лениво при первом клике
        statusBarItem?.menu = statusBarMenu
    }
    
    // Создание auto-layout submenu (lazy)
    private func createAutoLayoutMenu() -> NSMenu {
        let menu = NSMenu()
        menu.autoenablesItems = false // Оптимизация: не проверять enabled автоматически
        
        menu.addItem(NSMenuItem(title: "Сетка", action: #selector(applyGridLayout), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Горизонтально", action: #selector(applyHorizontalLayout), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Вертикально", action: #selector(applyVerticalLayout), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Каскад", action: #selector(applyCascadeLayout), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Фибоначчи", action: #selector(applyFibonacciLayout), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Фокус", action: #selector(applyFocusLayout), keyEquivalent: ""))
        
        return menu
    }
    
    // Создание основного меню (вызывается лениво)
    private func createMenu() -> NSMenu {
        let menu = NSMenu()
        menu.autoenablesItems = false // Оптимизация
        menu.minimumWidth = 200 // Фиксированная ширина = меньше layout расчетов
        
        menu.addItem(NSMenuItem(title: "Открыть настройки", action: #selector(openSettings), keyEquivalent: ","))
        menu.addItem(NSMenuItem.separator())
        
        // Быстрые действия - только самые используемые
        menu.addItem(NSMenuItem(title: "Левая половина", action: #selector(snapLeft), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Правая половина", action: #selector(snapRight), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Центрировать", action: #selector(center), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Максимизировать", action: #selector(maximize), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        
        // Автолайаут с lazy submenu
        let autoLayoutItem = NSMenuItem(title: "Автолайаут", action: nil, keyEquivalent: "")
        // Submenu создается только при первом открытии
        autoLayoutItem.submenu = autoLayoutSubmenu
        menu.addItem(autoLayoutItem)
        menu.addItem(NSMenuItem.separator())
        
        menu.addItem(NSMenuItem(title: "Выйти", action: #selector(quit), keyEquivalent: "q"))
        
        return menu
    }
    
    @objc private func openSettings() {
        NSApp.activate(ignoringOtherApps: true)
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
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
