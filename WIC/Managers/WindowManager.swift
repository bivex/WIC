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
    
    // Кеш для оптимизации
    private var cachedFrontmostWindow: (window: AXUIElement, timestamp: Date)?
    private let windowCacheDuration: TimeInterval = 0.5 // 500ms кеш (увеличено для производительности)
    
    private init() {
        Logger.shared.info("Initializing WindowManager")
        let initTimer = Logger.shared.startOperation("WindowManager Init")
        
        updateDisplays()
        setupDisplayReconfigurationCallback()
        // Mouse tracking отключен по умолчанию для экономии памяти
        // setupMouseTracking()
        
        initTimer.end()
        Logger.shared.info("WindowManager initialized with \(currentDisplays.count) display(s)")
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
        autoreleasepool {
            #if DEBUG
            Logger.shared.debug("Snapping window to: \(position.displayName)")
            let timer = Logger.shared.startOperation("Snap Window")
            defer { timer.end() }
            #endif
            
            guard let window = getFrontmostWindow() else {
                #if DEBUG
                Logger.shared.warning("No frontmost window found")
                #endif
                return
            }
            guard let screen = NSScreen.main else {
                #if DEBUG
                Logger.shared.warning("No main screen found")
                #endif
                return
            }
            
            let targetFrame = position.calculateFrame(for: screen)
            #if DEBUG
            Logger.shared.debug("Target frame: \(targetFrame)")
            #endif
            setWindowFrame(window, to: targetFrame)
        }
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
        // Используем кеш для частых вызовов
        if let cached = cachedFrontmostWindow,
           Date().timeIntervalSince(cached.timestamp) < windowCacheDuration {
            return cached.window
        }
        
        let systemWide = AXUIElementCreateSystemWide()
        var focusedApp: CFTypeRef?
        
        let result = AXUIElementCopyAttributeValue(
            systemWide,
            kAXFocusedApplicationAttribute as CFString,
            &focusedApp
        )
        
        guard result == .success, let app = focusedApp else { 
            cachedFrontmostWindow = nil
            return nil 
        }
        
        var focusedWindow: CFTypeRef?
        let windowResult = AXUIElementCopyAttributeValue(
            app as! AXUIElement,
            kAXFocusedWindowAttribute as CFString,
            &focusedWindow
        )
        
        guard windowResult == .success, let window = focusedWindow else {
            cachedFrontmostWindow = nil
            return nil
        }
        
        let axWindow = (window as! AXUIElement)
        
        // Обновляем кеш
        cachedFrontmostWindow = (axWindow, Date())
        return axWindow
    }
    
    private func setWindowFrame(_ window: AXUIElement, to frame: CGRect) {
        autoreleasepool {
            // Использовать batch установку для уменьшения вызовов AX API
            var position = CGPoint(x: frame.origin.x, y: frame.origin.y)
            var size = CGSize(width: frame.size.width, height: frame.size.height)
            
            if let positionValue = AXValueCreate(.cgPoint, &position),
               let sizeValue = AXValueCreate(.cgSize, &size) {
                AXUIElementSetAttributeValue(window, kAXPositionAttribute as CFString, positionValue)
                AXUIElementSetAttributeValue(window, kAXSizeAttribute as CFString, sizeValue)
            }
        }
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
    
    // MARK: - Auto Layout
    
    /// Получить количество видимых окон
    func getVisibleWindowsCount() -> Int {
        return AccessibilityHelper.getAllWindows().count
    }
    
    /// Применить автоматическую раскладку
    func applyAutoLayout(_ layoutType: AutoLayoutType) {
        autoreleasepool {
            Logger.shared.info("Applying auto-layout: \(layoutType.displayName)")
            let timer = Logger.shared.startOperation("Auto Layout - \(layoutType.displayName)")
            
            let windows = AccessibilityHelper.getAllWindows()
            guard !windows.isEmpty else {
                Logger.shared.warning("No windows found for auto-layout")
                return
            }
            Logger.shared.debug("Found \(windows.count) window(s) to arrange")
            
            guard let screen = NSScreen.main else {
                Logger.shared.warning("No main screen found")
                return
            }
            
            let visibleFrame = screen.visibleFrame
            Logger.shared.debug("Screen frame: \(visibleFrame)")
        
        switch layoutType {
        case .grid:
            applyGridLayout(windows: windows, in: visibleFrame)
        case .horizontal:
            applyHorizontalLayout(windows: windows, in: visibleFrame)
        case .vertical:
            applyVerticalLayout(windows: windows, in: visibleFrame)
        case .cascade:
            applyCascadeLayout(windows: windows, in: visibleFrame)
        case .fibonacci:
            applyFibonacciLayout(windows: windows, in: visibleFrame)
        case .focus:
            applyFocusLayout(windows: windows, in: visibleFrame)

        // Умные режимы
        case .readingMode:
            applyReadingModeLayout(windows: windows, in: visibleFrame)
        case .codingMode:
            applyCodingModeLayout(windows: windows, in: visibleFrame)
        case .designMode:
            applyDesignModeLayout(windows: windows, in: visibleFrame)
        case .communicationMode:
            applyCommunicationModeLayout(windows: windows, in: visibleFrame)
        case .researchMode:
            applyResearchModeLayout(windows: windows, in: visibleFrame)
        case .presentationMode:
            applyPresentationModeLayout(windows: windows, in: visibleFrame)
        case .multiTaskMode:
            applyMultiTaskModeLayout(windows: windows, in: visibleFrame)
        case .ultraWideMode:
            applyUltraWideModeLayout(windows: windows, in: visibleFrame, screen: screen)
            }
            
            timer.end()
            Logger.shared.info("Auto-layout applied successfully")
        }
    }
    
    /// Сбросить все окна в исходное состояние (центрировать)
    func resetAllWindows() {
        let windows = AccessibilityHelper.getAllWindows()
        guard let screen = NSScreen.main else { return }
        
        let visibleFrame = screen.visibleFrame
        let defaultSize = CGSize(width: 800, height: 600)
        
        for (index, window) in windows.enumerated() {
            let offset = CGFloat(index * 30)
            let frame = CGRect(
                x: visibleFrame.midX - defaultSize.width / 2 + offset,
                y: visibleFrame.midY - defaultSize.height / 2 + offset,
                width: defaultSize.width,
                height: defaultSize.height
            )
            AccessibilityHelper.setWindowFrame(window, to: frame)
        }
    }
    
    // MARK: - Private Layout Methods
    
    private func applyGridLayout(windows: [AXUIElement], in frame: CGRect) {
        Logger.shared.debug("Applying grid layout to \(windows.count) windows")
        Logger.shared.debug("Using visibleFrame (excludes Dock/MenuBar): \(frame)")
        let count = windows.count
        let columns = Int(ceil(sqrt(Double(count))))
        let rows = Int(ceil(Double(count) / Double(columns)))
        Logger.shared.debug("Grid: \(columns)x\(rows)")
        
        // Добавляем отступы от краёв (10px для надёжности)
        let padding: CGFloat = 10
        let usableFrame = CGRect(
            x: frame.minX + padding,
            y: frame.minY + padding,
            width: frame.width - padding * 2,
            height: frame.height - padding * 2
        )
        Logger.shared.debug("Added \(padding)px padding, usable area: \(usableFrame)")
        
        let windowWidth = usableFrame.width / CGFloat(columns)
        let windowHeight = usableFrame.height / CGFloat(rows)
        Logger.shared.debug("Each window size: \(windowWidth) x \(windowHeight)")
        
        // Batch process windows in groups to reduce memory pressure
        let batchSize = 5
        for batchStart in stride(from: 0, to: windows.count, by: batchSize) {
            autoreleasepool {
                let batchEnd = min(batchStart + batchSize, windows.count)
                let batch = windows[batchStart..<batchEnd]
                
                for (index, window) in batch.enumerated() {
                    let globalIndex = batchStart + index
                    let col = globalIndex % columns
                    let row = globalIndex / columns
                    
                    let windowFrame = CGRect(
                        x: usableFrame.minX + CGFloat(col) * windowWidth,
                        y: usableFrame.minY + CGFloat(row) * windowHeight,
                        width: windowWidth,
                        height: windowHeight
                    )
                    
                    #if DEBUG
                    if globalIndex == 0 {
                        Logger.shared.debug("First window frame: \(windowFrame)")
                    }
                    #endif
                    
                    AccessibilityHelper.setWindowFrame(window, to: windowFrame)
                }
            }
        }
    }
    
    private func applyHorizontalLayout(windows: [AXUIElement], in frame: CGRect) {
        autoreleasepool {
            let windowWidth = frame.width / CGFloat(windows.count)
            
            for (index, window) in windows.enumerated() {
                let windowFrame = CGRect(
                    x: frame.minX + CGFloat(index) * windowWidth,
                    y: frame.minY,
                    width: windowWidth,
                    height: frame.height
                )
                
                AccessibilityHelper.setWindowFrame(window, to: windowFrame)
            }
        }
    }
    
    private func applyVerticalLayout(windows: [AXUIElement], in frame: CGRect) {
        autoreleasepool {
            let windowHeight = frame.height / CGFloat(windows.count)
            
            for (index, window) in windows.enumerated() {
                let windowFrame = CGRect(
                    x: frame.minX,
                    y: frame.minY + CGFloat(index) * windowHeight,
                    width: frame.width,
                    height: windowHeight
                )
                
                AccessibilityHelper.setWindowFrame(window, to: windowFrame)
            }
        }
    }
    
    private func applyCascadeLayout(windows: [AXUIElement], in frame: CGRect) {
        let baseWidth = min(frame.width * 0.7, 1000)
        let baseHeight = min(frame.height * 0.7, 700)
        let offset: CGFloat = 30
        
        for (index, window) in windows.enumerated() {
            let windowFrame = CGRect(
                x: frame.minX + offset * CGFloat(index),
                y: frame.maxY - baseHeight - offset * CGFloat(index),
                width: baseWidth,
                height: baseHeight
            )
            
            AccessibilityHelper.setWindowFrame(window, to: windowFrame)
        }
    }
    
    private func applyFibonacciLayout(windows: [AXUIElement], in frame: CGRect) {
        guard !windows.isEmpty else { return }
        
        // Первое окно занимает большую часть
        let mainFrame = CGRect(
            x: frame.minX,
            y: frame.minY,
            width: frame.width * 0.618, // Золотое сечение
            height: frame.height
        )
        AccessibilityHelper.setWindowFrame(windows[0], to: mainFrame)
        
        // Остальные окна делят оставшееся пространство
        if windows.count > 1 {
            let remainingWindows = Array(windows[1...])
            let sideFrame = CGRect(
                x: frame.minX + frame.width * 0.618,
                y: frame.minY,
                width: frame.width * 0.382,
                height: frame.height
            )
            
            let windowHeight = sideFrame.height / CGFloat(remainingWindows.count)
            
            for (index, window) in remainingWindows.enumerated() {
                let windowFrame = CGRect(
                    x: sideFrame.minX,
                    y: sideFrame.minY + CGFloat(index) * windowHeight,
                    width: sideFrame.width,
                    height: windowHeight
                )
                AccessibilityHelper.setWindowFrame(window, to: windowFrame)
            }
        }
    }
    
    private func applyFocusLayout(windows: [AXUIElement], in frame: CGRect) {
        guard !windows.isEmpty else { return }
        
        // Главное окно занимает 2/3 слева
        let mainFrame = CGRect(
            x: frame.minX,
            y: frame.minY,
            width: frame.width * 2 / 3,
            height: frame.height
        )
        AccessibilityHelper.setWindowFrame(windows[0], to: mainFrame)
        
        // Остальные окна делят правую треть
        if windows.count > 1 {
            let remainingWindows = Array(windows[1...])
            let sideFrame = CGRect(
                x: frame.minX + frame.width * 2 / 3,
                y: frame.minY,
                width: frame.width / 3,
                height: frame.height
            )
            
            let windowHeight = sideFrame.height / CGFloat(remainingWindows.count)
            
            for (index, window) in remainingWindows.enumerated() {
                let windowFrame = CGRect(
                    x: sideFrame.minX,
                    y: sideFrame.minY + CGFloat(index) * windowHeight,
                    width: sideFrame.width,
                    height: windowHeight
                )
                AccessibilityHelper.setWindowFrame(window, to: windowFrame)
            }
        }
    }

    // MARK: - Smart Layout Methods (BookingExpert UI)

    /// Режим чтения: оптимальная ширина для чтения текста
    private func applyReadingModeLayout(windows: [AXUIElement], in frame: CGRect) {
        guard !windows.isEmpty else { return }

        // Оптимальная ширина для чтения: 65-75 символов (примерно 600-800px)
        let optimalWidth: CGFloat = min(800, frame.width * 0.5)
        let centerX = frame.midX - optimalWidth / 2

        if windows.count == 1 {
            // Одно окно - центрируем с оптимальной шириной
            let readingFrame = CGRect(
                x: centerX,
                y: frame.minY,
                width: optimalWidth,
                height: frame.height
            )
            AccessibilityHelper.setWindowFrame(windows[0], to: readingFrame)
        } else {
            // Несколько окон - основное в центре, остальные по бокам
            let mainFrame = CGRect(
                x: centerX,
                y: frame.minY,
                width: optimalWidth,
                height: frame.height
            )
            AccessibilityHelper.setWindowFrame(windows[0], to: mainFrame)

            if windows.count > 1 {
                let sideWidth = (frame.width - optimalWidth) / 2 - 20
                let remainingWindows = Array(windows[1...])

                for (index, window) in remainingWindows.enumerated() {
                    let isLeft = index % 2 == 0
                    let sideFrame = CGRect(
                        x: isLeft ? frame.minX : frame.maxX - sideWidth,
                        y: frame.minY,
                        width: sideWidth,
                        height: frame.height
                    )
                    AccessibilityHelper.setWindowFrame(window, to: sideFrame)
                }
            }
        }
    }

    /// Режим кодирования: редактор + терминал
    private func applyCodingModeLayout(windows: [AXUIElement], in frame: CGRect) {
        guard !windows.isEmpty else { return }

        if windows.count == 1 {
            // Одно окно - максимизировать
            AccessibilityHelper.setWindowFrame(windows[0], to: frame)
        } else if windows.count == 2 {
            // Два окна: редактор (60%) слева, терминал (40%) справа
            let editorWidth = frame.width * 0.6

            let editorFrame = CGRect(
                x: frame.minX,
                y: frame.minY,
                width: editorWidth,
                height: frame.height
            )
            AccessibilityHelper.setWindowFrame(windows[0], to: editorFrame)

            let terminalFrame = CGRect(
                x: frame.minX + editorWidth,
                y: frame.minY,
                width: frame.width - editorWidth,
                height: frame.height
            )
            AccessibilityHelper.setWindowFrame(windows[1], to: terminalFrame)
        } else {
            // Три и более: редактор (60%) слева, остальные делят правую часть
            let editorWidth = frame.width * 0.6

            let editorFrame = CGRect(
                x: frame.minX,
                y: frame.minY,
                width: editorWidth,
                height: frame.height
            )
            AccessibilityHelper.setWindowFrame(windows[0], to: editorFrame)

            let remainingWindows = Array(windows[1...])
            let rightWidth = frame.width - editorWidth
            let windowHeight = frame.height / CGFloat(remainingWindows.count)

            for (index, window) in remainingWindows.enumerated() {
                let windowFrame = CGRect(
                    x: frame.minX + editorWidth,
                    y: frame.minY + CGFloat(index) * windowHeight,
                    width: rightWidth,
                    height: windowHeight
                )
                AccessibilityHelper.setWindowFrame(window, to: windowFrame)
            }
        }
    }

    /// Режим дизайна: большой canvas + инструменты
    private func applyDesignModeLayout(windows: [AXUIElement], in frame: CGRect) {
        guard !windows.isEmpty else { return }

        if windows.count == 1 {
            // Одно окно - максимизировать
            AccessibilityHelper.setWindowFrame(windows[0], to: frame)
        } else {
            // Canvas занимает 70% слева, инструменты 30% справа
            let canvasWidth = frame.width * 0.7

            let canvasFrame = CGRect(
                x: frame.minX,
                y: frame.minY,
                width: canvasWidth,
                height: frame.height
            )
            AccessibilityHelper.setWindowFrame(windows[0], to: canvasFrame)

            // Остальные окна делят правую панель
            let remainingWindows = Array(windows[1...])
            let toolsWidth = frame.width - canvasWidth
            let windowHeight = frame.height / CGFloat(remainingWindows.count)

            for (index, window) in remainingWindows.enumerated() {
                let windowFrame = CGRect(
                    x: frame.minX + canvasWidth,
                    y: frame.minY + CGFloat(index) * windowHeight,
                    width: toolsWidth,
                    height: windowHeight
                )
                AccessibilityHelper.setWindowFrame(window, to: windowFrame)
            }
        }
    }

    /// Режим общения: видеозвонок + чат/заметки
    private func applyCommunicationModeLayout(windows: [AXUIElement], in frame: CGRect) {
        guard !windows.isEmpty else { return }

        if windows.count == 1 {
            // Одно окно - центрируем с соотношением 16:9
            let videoWidth = min(frame.width * 0.8, frame.height * 16 / 9)
            let videoHeight = videoWidth * 9 / 16

            let videoFrame = CGRect(
                x: frame.midX - videoWidth / 2,
                y: frame.midY - videoHeight / 2,
                width: videoWidth,
                height: videoHeight
            )
            AccessibilityHelper.setWindowFrame(windows[0], to: videoFrame)
        } else if windows.count == 2 {
            // Видео (65%) слева, чат (35%) справа
            let videoWidth = frame.width * 0.65

            let videoFrame = CGRect(
                x: frame.minX,
                y: frame.minY,
                width: videoWidth,
                height: frame.height
            )
            AccessibilityHelper.setWindowFrame(windows[0], to: videoFrame)

            let chatFrame = CGRect(
                x: frame.minX + videoWidth,
                y: frame.minY,
                width: frame.width - videoWidth,
                height: frame.height
            )
            AccessibilityHelper.setWindowFrame(windows[1], to: chatFrame)
        } else {
            // Видео сверху (70%), остальные снизу
            let videoHeight = frame.height * 0.7

            let videoFrame = CGRect(
                x: frame.minX,
                y: frame.minY + frame.height - videoHeight,
                width: frame.width,
                height: videoHeight
            )
            AccessibilityHelper.setWindowFrame(windows[0], to: videoFrame)

            let remainingWindows = Array(windows[1...])
            let bottomHeight = frame.height - videoHeight
            let windowWidth = frame.width / CGFloat(remainingWindows.count)

            for (index, window) in remainingWindows.enumerated() {
                let windowFrame = CGRect(
                    x: frame.minX + CGFloat(index) * windowWidth,
                    y: frame.minY,
                    width: windowWidth,
                    height: bottomHeight
                )
                AccessibilityHelper.setWindowFrame(window, to: windowFrame)
            }
        }
    }

    /// Режим исследования: 4 квадранта для сравнения источников
    private func applyResearchModeLayout(windows: [AXUIElement], in frame: CGRect) {
        guard !windows.isEmpty else { return }

        // Делим экран на 4 квадранта независимо от количества окон
        let halfWidth = frame.width / 2
        let halfHeight = frame.height / 2

        let quadrants = [
            CGRect(x: frame.minX, y: frame.minY + halfHeight, width: halfWidth, height: halfHeight), // Top-left
            CGRect(x: frame.minX + halfWidth, y: frame.minY + halfHeight, width: halfWidth, height: halfHeight), // Top-right
            CGRect(x: frame.minX, y: frame.minY, width: halfWidth, height: halfHeight), // Bottom-left
            CGRect(x: frame.minX + halfWidth, y: frame.minY, width: halfWidth, height: halfHeight) // Bottom-right
        ]

        for (index, window) in windows.enumerated() {
            let quadrantIndex = index % 4
            AccessibilityHelper.setWindowFrame(window, to: quadrants[quadrantIndex])
        }
    }

    /// Режим презентации: слайды + заметки
    private func applyPresentationModeLayout(windows: [AXUIElement], in frame: CGRect) {
        guard !windows.isEmpty else { return }

        if windows.count == 1 {
            // Одно окно - максимизировать
            AccessibilityHelper.setWindowFrame(windows[0], to: frame)
        } else {
            // Презентация занимает 75% сверху, заметки 25% снизу
            let presentationHeight = frame.height * 0.75

            let presentationFrame = CGRect(
                x: frame.minX,
                y: frame.minY + frame.height - presentationHeight,
                width: frame.width,
                height: presentationHeight
            )
            AccessibilityHelper.setWindowFrame(windows[0], to: presentationFrame)

            // Остальные окна делят нижнюю часть
            let remainingWindows = Array(windows[1...])
            let notesHeight = frame.height - presentationHeight
            let windowWidth = frame.width / CGFloat(remainingWindows.count)

            for (index, window) in remainingWindows.enumerated() {
                let windowFrame = CGRect(
                    x: frame.minX + CGFloat(index) * windowWidth,
                    y: frame.minY,
                    width: windowWidth,
                    height: notesHeight
                )
                AccessibilityHelper.setWindowFrame(window, to: windowFrame)
            }
        }
    }

    /// Многозадачный режим: умное адаптивное распределение
    private func applyMultiTaskModeLayout(windows: [AXUIElement], in frame: CGRect) {
        guard !windows.isEmpty else { return }

        let count = windows.count

        switch count {
        case 1:
            // 1 окно: максимизировать
            AccessibilityHelper.setWindowFrame(windows[0], to: frame)

        case 2:
            // 2 окна: 50/50 по вертикали
            let halfWidth = frame.width / 2
            for (index, window) in windows.enumerated() {
                let windowFrame = CGRect(
                    x: frame.minX + CGFloat(index) * halfWidth,
                    y: frame.minY,
                    width: halfWidth,
                    height: frame.height
                )
                AccessibilityHelper.setWindowFrame(window, to: windowFrame)
            }

        case 3:
            // 3 окна: 50% слева, 2x25% справа
            let halfWidth = frame.width / 2
            let halfHeight = frame.height / 2

            AccessibilityHelper.setWindowFrame(windows[0], to: CGRect(
                x: frame.minX,
                y: frame.minY,
                width: halfWidth,
                height: frame.height
            ))

            AccessibilityHelper.setWindowFrame(windows[1], to: CGRect(
                x: frame.minX + halfWidth,
                y: frame.minY + halfHeight,
                width: halfWidth,
                height: halfHeight
            ))

            AccessibilityHelper.setWindowFrame(windows[2], to: CGRect(
                x: frame.minX + halfWidth,
                y: frame.minY,
                width: halfWidth,
                height: halfHeight
            ))

        case 4:
            // 4 окна: квадранты
            applyResearchModeLayout(windows: windows, in: frame)

        case 5, 6:
            // 5-6 окон: сетка 2x3
            let columns = 3
            let rows = 2
            let windowWidth = frame.width / CGFloat(columns)
            let windowHeight = frame.height / CGFloat(rows)

            for (index, window) in windows.enumerated() {
                let col = index % columns
                let row = index / columns

                let windowFrame = CGRect(
                    x: frame.minX + CGFloat(col) * windowWidth,
                    y: frame.minY + CGFloat(row) * windowHeight,
                    width: windowWidth,
                    height: windowHeight
                )
                AccessibilityHelper.setWindowFrame(window, to: windowFrame)
            }

        default:
            // Больше 6: динамическая сетка
            applyGridLayout(windows: windows, in: frame)
        }
    }

    /// Ультраширокий режим: оптимизация для 21:9 и 32:9
    private func applyUltraWideModeLayout(windows: [AXUIElement], in frame: CGRect, screen: NSScreen) {
        guard !windows.isEmpty else { return }

        let aspectRatio = frame.width / frame.height

        // Проверяем, действительно ли это ультраширокий экран
        if aspectRatio < 2.0 {
            // Обычный экран - используем режим фокуса
            applyFocusLayout(windows: windows, in: frame)
            return
        }

        // Ультраширокий экран: три колонки
        if windows.count == 1 {
            // Одно окно - центральная колонка с оптимальной шириной
            let optimalWidth = min(frame.width * 0.5, 1600)
            let centerFrame = CGRect(
                x: frame.midX - optimalWidth / 2,
                y: frame.minY,
                width: optimalWidth,
                height: frame.height
            )
            AccessibilityHelper.setWindowFrame(windows[0], to: centerFrame)

        } else if windows.count == 2 {
            // Два окна: центр (60%) + правая колонка (40%)
            let centerWidth = frame.width * 0.6

            AccessibilityHelper.setWindowFrame(windows[0], to: CGRect(
                x: frame.midX - centerWidth / 2,
                y: frame.minY,
                width: centerWidth,
                height: frame.height
            ))

            AccessibilityHelper.setWindowFrame(windows[1], to: CGRect(
                x: frame.minX + frame.width - frame.width * 0.25,
                y: frame.minY,
                width: frame.width * 0.25,
                height: frame.height
            ))

        } else {
            // Три и более: три колонки (25% - 50% - 25%)
            let leftWidth = frame.width * 0.25
            let centerWidth = frame.width * 0.5
            let rightWidth = frame.width * 0.25

            // Центральное окно
            AccessibilityHelper.setWindowFrame(windows[0], to: CGRect(
                x: frame.minX + leftWidth,
                y: frame.minY,
                width: centerWidth,
                height: frame.height
            ))

            // Левая колонка
            if windows.count > 1 {
                let leftWindows = windows.count > 2 ? Array(windows[1...((windows.count - 1) / 2)]) : [windows[1]]
                let leftWindowHeight = frame.height / CGFloat(leftWindows.count)

                for (index, window) in leftWindows.enumerated() {
                    AccessibilityHelper.setWindowFrame(window, to: CGRect(
                        x: frame.minX,
                        y: frame.minY + CGFloat(index) * leftWindowHeight,
                        width: leftWidth,
                        height: leftWindowHeight
                    ))
                }

                // Правая колонка
                if windows.count > 2 {
                    let rightWindowsStartIndex = leftWindows.count + 1
                    let rightWindows = Array(windows[rightWindowsStartIndex...])
                    let rightWindowHeight = frame.height / CGFloat(rightWindows.count)

                    for (index, window) in rightWindows.enumerated() {
                        AccessibilityHelper.setWindowFrame(window, to: CGRect(
                            x: frame.minX + leftWidth + centerWidth,
                            y: frame.minY + CGFloat(index) * rightWindowHeight,
                            width: rightWidth,
                            height: rightWindowHeight
                        ))
                    }
                }
            }
        }
    }
}

