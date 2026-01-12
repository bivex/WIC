//
//  AccessibilityHelper.swift
//  WIC
//
//  Вспомогательные функции для работы с Accessibility API
//

import Foundation
import AppKit

class AccessibilityHelper {
    
    // MARK: - Caching
    private static var cachedWindows: (windows: [AXUIElement], timestamp: Date)?
    private static let windowCacheDuration: TimeInterval = 0.3 // 300ms cache
    
    // MARK: - Permission Checks
    
    static func checkAccessibilityPermission() -> Bool {
        let hasPermission = AXIsProcessTrusted()
        Logger.shared.debug("Accessibility permission: \(hasPermission ? "granted" : "denied")")
        return hasPermission
    }
    
    static func requestAccessibilityPermission() {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        AXIsProcessTrustedWithOptions(options)
    }
    
    // MARK: - Window Information
    
    /// Список системных приложений, которые нужно пропускать
    private static let systemAppsToSkip: Set<String> = [
        "com.apple.systemuiserver",
        "com.apple.controlcenter",
        "com.apple.notificationcenterui",
        "com.apple.dock",
        "com.apple.WindowManager",
        "com.apple.loginwindow",
        "com.apple.Spotlight",
        "com.apple.finder" // Finder часто создает невидимые окна
    ]
    
    static func getAllWindows() -> [AXUIElement] {
        // Использовать кеш для частых запросов
        if let cached = cachedWindows,
           Date().timeIntervalSince(cached.timestamp) < windowCacheDuration {
            Logger.shared.debug("Returning cached windows: \(cached.windows.count)")
            return cached.windows
        }
        
        return autoreleasepool {
            Logger.shared.debug("Getting all windows...")
            let timer = Logger.shared.startOperation("Get All Windows")
            var windows: [AXUIElement] = []
            
            guard let runningApps = NSWorkspace.shared.runningApplications as [NSRunningApplication]? else {
                Logger.shared.warning("Could not get running applications")
                return windows
            }
            
            // Фильтруем приложения для оптимизации
            let filteredApps = runningApps.filter { app in
                // Пропускаем системные приложения
                if let bundleId = app.bundleIdentifier, systemAppsToSkip.contains(bundleId) {
                    return false
                }
                
                // Пропускаем фоновые приложения без UI
                if app.activationPolicy != .regular {
                    return false
                }
                
                // Пропускаем скрытые приложения
                if app.isHidden {
                    return false
                }
                
                return true
            }
            
            Logger.shared.debug("Scanning \(filteredApps.count) apps (filtered from \(runningApps.count))")
            
            var processedApps = 0
            var skippedApps = 0
        
        for app in filteredApps {
            let appElement = AXUIElementCreateApplication(app.processIdentifier)
            
            var windowList: CFTypeRef?
            let result = AXUIElementCopyAttributeValue(
                appElement,
                kAXWindowsAttribute as CFString,
                &windowList
            )
            
            if result == .success, let list = windowList as? [AXUIElement] {
                // Фильтруем окна: только стандартные видимые окна
                let validWindows = list.filter { window in
                    guard let info = getWindowInfo(window) else { return false }
                    
                    // Пропускаем слишком маленькие окна (вероятно системные)
                    if info.frame.width < 100 || info.frame.height < 100 {
                        return false
                    }
                    
                    // Проверяем что окно на экране
                    let isOnScreen = NSScreen.screens.contains { screen in
                        screen.frame.intersects(info.frame)
                    }
                    
                    return isOnScreen
                }
                
                windows.append(contentsOf: validWindows)
                processedApps += 1
            } else {
                skippedApps += 1
            }
        }
        
        timer.end()
        Logger.shared.debug("Found \(windows.count) window(s) from \(processedApps) apps (skipped \(skippedApps))")
        
        // Обновить кеш
        cachedWindows = (windows, Date())
        return windows
        }
    }
    
    static func getWindowInfo(_ window: AXUIElement) -> WindowInfo? {
        var title: CFTypeRef?
        var position: CFTypeRef?
        var size: CFTypeRef?
        
        // Получить заголовок
        AXUIElementCopyAttributeValue(window, kAXTitleAttribute as CFString, &title)
        
        // Получить позицию
        let posResult = AXUIElementCopyAttributeValue(window, kAXPositionAttribute as CFString, &position)
        guard posResult == .success, let posValue = position else { return nil }
        
        var windowPosition = CGPoint.zero
        AXValueGetValue(posValue as! AXValue, .cgPoint, &windowPosition)
        
        // Получить размер
        let sizeResult = AXUIElementCopyAttributeValue(window, kAXSizeAttribute as CFString, &size)
        guard sizeResult == .success, let sizeValue = size else { return nil }
        
        var windowSize = CGSize.zero
        AXValueGetValue(sizeValue as! AXValue, .cgSize, &windowSize)
        
        return WindowInfo(
            element: window,
            title: title as? String ?? "Unknown",
            frame: CGRect(origin: windowPosition, size: windowSize)
        )
    }
    
    // MARK: - Window Manipulation

    @discardableResult
    static func setWindowPosition(_ window: AXUIElement, to position: CGPoint) -> Bool {
        var point = position
        let positionValue = AXValueCreate(.cgPoint, &point)
        let result = AXUIElementSetAttributeValue(
            window,
            kAXPositionAttribute as CFString,
            positionValue!
        )
        return result == .success
    }

    @discardableResult
    static func setWindowSize(_ window: AXUIElement, to size: CGSize) -> Bool {
        var windowSize = size
        let sizeValue = AXValueCreate(.cgSize, &windowSize)
        let result = AXUIElementSetAttributeValue(
            window,
            kAXSizeAttribute as CFString,
            sizeValue!
        )
        return result == .success
    }

    @discardableResult
    static func setWindowFrame(_ window: AXUIElement, to frame: CGRect) -> Bool {
        autoreleasepool {
            // Batch установка - оба значения за один раз
            var position = frame.origin
            var size = frame.size
            
            var success = true
            if let positionValue = AXValueCreate(.cgPoint, &position) {
                let result = AXUIElementSetAttributeValue(window, kAXPositionAttribute as CFString, positionValue)
                success = success && (result == .success)
            } else {
                success = false
            }
            
            if let sizeValue = AXValueCreate(.cgSize, &size) {
                let result = AXUIElementSetAttributeValue(window, kAXSizeAttribute as CFString, sizeValue)
                success = success && (result == .success)
            } else {
                success = false
            }
            
            return success
        }
    }
    
    /// Get the current frame of a window
    static func getWindowFrame(_ window: AXUIElement) -> CGRect? {
        autoreleasepool {
            var positionValue: CFTypeRef?
            var sizeValue: CFTypeRef?
            
            // Get position
            let positionResult = AXUIElementCopyAttributeValue(
                window,
                kAXPositionAttribute as CFString,
                &positionValue
            )
            
            // Get size
            let sizeResult = AXUIElementCopyAttributeValue(
                window,
                kAXSizeAttribute as CFString,
                &sizeValue
            )
            
            guard positionResult == .success,
                  sizeResult == .success,
                  let positionValue = positionValue,
                  let sizeValue = sizeValue else {
                return nil
            }
            
            var position = CGPoint.zero
            var size = CGSize.zero
            
            guard AXValueGetValue(positionValue as! AXValue, .cgPoint, &position),
                  AXValueGetValue(sizeValue as! AXValue, .cgSize, &size) else {
                return nil
            }
            
            return CGRect(origin: position, size: size)
        }
    }
    
    // MARK: - App Information
    
    static func getFocusedApp() -> NSRunningApplication? {
        return NSWorkspace.shared.frontmostApplication
    }
    
    static func getFocusedWindow() -> AXUIElement? {
        let systemWide = AXUIElementCreateSystemWide()
        var focusedApp: CFTypeRef?
        
        let result = AXUIElementCopyAttributeValue(
            systemWide,
            kAXFocusedApplicationAttribute as CFString,
            &focusedApp
        )
        
        guard result == .success, let app = focusedApp else { return nil }
        
        var focusedWindow: CFTypeRef?
        let windowResult = AXUIElementCopyAttributeValue(
            app as! AXUIElement,
            kAXFocusedWindowAttribute as CFString,
            &focusedWindow
        )
        
        guard windowResult == .success else { return nil }
        
        return (focusedWindow as! AXUIElement)
    }
    
    // MARK: - Screen Information
    
    static func getScreenContainingWindow(_ window: AXUIElement) -> NSScreen? {
        guard let windowInfo = getWindowInfo(window) else { return nil }
        
        return NSScreen.screens.first { screen in
            screen.frame.intersects(windowInfo.frame)
        }
    }
    
    static func getScreenAtPoint(_ point: CGPoint) -> NSScreen? {
        return NSScreen.screens.first { screen in
            screen.frame.contains(point)
        }
    }
}

// MARK: - Window Info Model

struct WindowInfo {
    let element: AXUIElement
    let title: String
    let frame: CGRect
}
