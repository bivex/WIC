//
//  AccessibilityHelper.swift
//  WIC
//
//  Вспомогательные функции для работы с Accessibility API
//

import Foundation
import AppKit

class AccessibilityHelper {
    
    // MARK: - Permission Checks
    
    static func checkAccessibilityPermission() -> Bool {
        return AXIsProcessTrusted()
    }
    
    static func requestAccessibilityPermission() {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        AXIsProcessTrustedWithOptions(options)
    }
    
    // MARK: - Window Information
    
    static func getAllWindows() -> [AXUIElement] {
        var windows: [AXUIElement] = []
        
        guard let runningApps = NSWorkspace.shared.runningApplications as [NSRunningApplication]? else {
            return windows
        }
        
        for app in runningApps {
            let appElement = AXUIElementCreateApplication(app.processIdentifier)
            
            var windowList: CFTypeRef?
            let result = AXUIElementCopyAttributeValue(
                appElement,
                kAXWindowsAttribute as CFString,
                &windowList
            )
            
            if result == .success, let list = windowList as? [AXUIElement] {
                windows.append(contentsOf: list)
            }
        }
        
        return windows
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
    
    static func setWindowFrame(_ window: AXUIElement, to frame: CGRect) -> Bool {
        let positionSuccess = setWindowPosition(window, to: frame.origin)
        let sizeSuccess = setWindowSize(window, to: frame.size)
        return positionSuccess && sizeSuccess
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
