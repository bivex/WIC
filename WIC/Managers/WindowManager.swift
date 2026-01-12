//
//  WindowManager.swift
//  WIC
//
//  Менеджер для управления окнами
//

import Foundation
import AppKit
import Combine

class WindowManager: ObservableObject {
    static let shared = WindowManager()
    
    @Published var snapSettings = SnapSettings()
    @Published var currentDisplays: [DisplayInfo] = []
    
    private var displayReconfigurationCallback: (() -> Void)?
    private var mouseMonitor: Any?
    private var isDragging = false
    
    private init() {
        updateDisplays()
        setupDisplayReconfigurationCallback()
        setupMouseTracking()
    }
    
    // MARK: - Display Management
    
    private func updateDisplays() {
        currentDisplays = DisplayInfo.getAllDisplays()
    }
    
    private func setupDisplayReconfigurationCallback() {
        // Отслеживание изменений конфигурации дисплеев
        let callback: CGDisplayReconfigurationCallBack = { _, _, _ in
            DispatchQueue.main.async {
                WindowManager.shared.updateDisplays()
            }
        }
        
        CGDisplayRegisterReconfigurationCallback(callback, nil)
    }
    
    // MARK: - Window Manipulation
    
    func snapWindow(to position: WindowPosition) {
        guard let window = getFrontmostWindow() else { return }
        guard let screen = NSScreen.main else { return }
        
        let targetFrame = position.calculateFrame(for: screen)
        setWindowFrame(window, to: targetFrame)
    }
    
    func centerWindow() {
        snapWindow(to: .center)
    }
    
    func maximizeWindow() {
        snapWindow(to: .maximize)
    }
    
    func moveWindowToDisplay(_ displayIndex: Int) {
        guard displayIndex < currentDisplays.count else { return }
        guard let window = getFrontmostWindow() else { return }
        
        let display = currentDisplays[displayIndex]
        let targetScreen = NSScreen.screens.first { screen in
            screen.frame.intersects(display.frame)
        }
        
        guard let screen = targetScreen else { return }
        
        // Переместить окно на центр нового дисплея
        let visibleFrame = screen.visibleFrame
        let currentSize = getWindowSize(window)
        
        let targetFrame = CGRect(
            x: visibleFrame.midX - currentSize.width / 2,
            y: visibleFrame.midY - currentSize.height / 2,
            width: currentSize.width,
            height: currentSize.height
        )
        
        setWindowFrame(window, to: targetFrame)
    }
    
    // MARK: - Auto-Snap Functionality
    
    private func setupMouseTracking() {
        guard snapSettings.isEnabled else { return }
        
        // Мониторинг движения мыши для auto-snap
        mouseMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDragged, .leftMouseUp]) { [weak self] event in
            guard let self = self else { return }
            
            if event.type == .leftMouseDragged {
                self.isDragging = true
                self.handleWindowDrag(at: event.locationInWindow)
            } else if event.type == .leftMouseUp && self.isDragging {
                self.isDragging = false
                self.handleWindowDragEnd(at: NSEvent.mouseLocation)
            }
        }
    }
    
    private func handleWindowDrag(at location: CGPoint) {
        // Проверка, находится ли окно близко к краю экрана
        // Показать превью позиции
    }
    
    private func handleWindowDragEnd(at location: CGPoint) {
        guard let screen = NSScreen.screens.first(where: { $0.frame.contains(location) }) else { return }
        
        let visibleFrame = screen.visibleFrame
        let threshold = snapSettings.snapThreshold
        
        // Проверить, близко ли курсор к краям экрана
        var targetPosition: WindowPosition?
        
        // Левый край
        if location.x - visibleFrame.minX < threshold {
            targetPosition = .leftHalf
        }
        // Правый край
        else if visibleFrame.maxX - location.x < threshold {
            targetPosition = .rightHalf
        }
        // Верхний край
        else if visibleFrame.maxY - location.y < threshold {
            // Проверить углы
            if location.x - visibleFrame.minX < threshold * 2 {
                targetPosition = .topLeftQuarter
            } else if visibleFrame.maxX - location.x < threshold * 2 {
                targetPosition = .topRightQuarter
            } else {
                targetPosition = .topHalf
            }
        }
        // Нижний край
        else if location.y - visibleFrame.minY < threshold {
            // Проверить углы
            if location.x - visibleFrame.minX < threshold * 2 {
                targetPosition = .bottomLeftQuarter
            } else if visibleFrame.maxX - location.x < threshold * 2 {
                targetPosition = .bottomRightQuarter
            } else {
                targetPosition = .bottomHalf
            }
        }
        
        if let position = targetPosition {
            snapWindow(to: position)
        }
    }
    
    // MARK: - Accessibility Helper Methods
    
    private func getFrontmostWindow() -> AXUIElement? {
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
    
    private func setWindowFrame(_ window: AXUIElement, to frame: CGRect) {
        // Установить позицию
        var position = CGPoint(x: frame.origin.x, y: frame.origin.y)
        let positionValue = AXValueCreate(.cgPoint, &position)
        AXUIElementSetAttributeValue(window, kAXPositionAttribute as CFString, positionValue!)
        
        // Установить размер
        var size = CGSize(width: frame.size.width, height: frame.size.height)
        let sizeValue = AXValueCreate(.cgSize, &size)
        AXUIElementSetAttributeValue(window, kAXSizeAttribute as CFString, sizeValue!)
    }
    
    private func getWindowSize(_ window: AXUIElement) -> CGSize {
        var sizeValue: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(
            window,
            kAXSizeAttribute as CFString,
            &sizeValue
        )
        
        guard result == .success,
              let value = sizeValue,
              AXValueGetType(value as! AXValue) == .cgSize else {
            return CGSize(width: 800, height: 600) // Размер по умолчанию
        }
        
        var size = CGSize.zero
        AXValueGetValue(value as! AXValue, .cgSize, &size)
        return size
    }
    
    // MARK: - Layout Presets
    
    func saveCurrentLayout(name: String) {
        // Сохранить текущую раскладку окон
        // TODO: Реализовать сохранение в UserDefaults
    }
    
    func restoreLayout(name: String) {
        // Восстановить сохраненную раскладку
        // TODO: Реализовать загрузку из UserDefaults
    }
}
