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
    var statusBarMenu: NSMenu?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Скрыть иконку в Dock
        NSApp.setActivationPolicy(.accessory)
        
        // Создать статус-бар меню
        setupStatusBarItem()
        
        // Проверить и запросить разрешения Accessibility
        checkAccessibilityPermissions()
        
        // Инициализировать менеджеры
        _ = WindowManager.shared
        _ = HotkeyManager.shared
    }
    
    private func setupStatusBarItem() {
        statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusBarItem?.button {
            // Использовать SF Symbol для иконки
            button.image = NSImage(systemSymbolName: "rectangle.split.3x3", accessibilityDescription: "WIC")
            button.image?.isTemplate = true
        }
        
        // Создать меню
        let menu = NSMenu()
        
        menu.addItem(NSMenuItem(title: "Открыть настройки", action: #selector(openSettings), keyEquivalent: ","))
        menu.addItem(NSMenuItem.separator())
        
        // Быстрые действия
        menu.addItem(NSMenuItem(title: "Левая половина", action: #selector(snapLeft), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Правая половина", action: #selector(snapRight), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Верхняя половина", action: #selector(snapTop), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Нижняя половина", action: #selector(snapBottom), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Центрировать", action: #selector(center), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Максимизировать", action: #selector(maximize), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        
        // Автолайаут
        let autoLayoutMenu = NSMenu()
        autoLayoutMenu.addItem(NSMenuItem(title: "Сетка", action: #selector(applyGridLayout), keyEquivalent: ""))
        autoLayoutMenu.addItem(NSMenuItem(title: "Горизонтально", action: #selector(applyHorizontalLayout), keyEquivalent: ""))
        autoLayoutMenu.addItem(NSMenuItem(title: "Вертикально", action: #selector(applyVerticalLayout), keyEquivalent: ""))
        autoLayoutMenu.addItem(NSMenuItem(title: "Каскад", action: #selector(applyCascadeLayout), keyEquivalent: ""))
        autoLayoutMenu.addItem(NSMenuItem(title: "Фибоначчи", action: #selector(applyFibonacciLayout), keyEquivalent: ""))
        autoLayoutMenu.addItem(NSMenuItem(title: "Фокус", action: #selector(applyFocusLayout), keyEquivalent: ""))
        
        let autoLayoutItem = NSMenuItem(title: "Автолайаут", action: nil, keyEquivalent: "")
        autoLayoutItem.submenu = autoLayoutMenu
        menu.addItem(autoLayoutItem)
        menu.addItem(NSMenuItem.separator())
        
        menu.addItem(NSMenuItem(title: "Выйти", action: #selector(quit), keyEquivalent: "q"))
        
        statusBarItem?.menu = menu
        statusBarMenu = menu
    }
    
    @objc private func openSettings() {
        NSApp.activate(ignoringOtherApps: true)
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
    }
    
    @objc private func snapLeft() {
        WindowManager.shared.snapWindow(to: .leftHalf)
    }
    
    @objc private func snapRight() {
        WindowManager.shared.snapWindow(to: .rightHalf)
    }
    
    @objc private func snapTop() {
        WindowManager.shared.snapWindow(to: .topHalf)
    }
    
    @objc private func snapBottom() {
        WindowManager.shared.snapWindow(to: .bottomHalf)
    }
    
    @objc private func center() {
        WindowManager.shared.centerWindow()
    }
    
    @objc private func maximize() {
        WindowManager.shared.maximizeWindow()
    }
    
    @objc private func applyGridLayout() {
        WindowManager.shared.applyAutoLayout(.grid)
    }
    
    @objc private func applyHorizontalLayout() {
        WindowManager.shared.applyAutoLayout(.horizontal)
    }
    
    @objc private func applyVerticalLayout() {
        WindowManager.shared.applyAutoLayout(.vertical)
    }
    
    @objc private func applyCascadeLayout() {
        WindowManager.shared.applyAutoLayout(.cascade)
    }
    
    @objc private func applyFibonacciLayout() {
        WindowManager.shared.applyAutoLayout(.fibonacci)
    }
    
    @objc private func applyFocusLayout() {
        WindowManager.shared.applyAutoLayout(.focus)
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
