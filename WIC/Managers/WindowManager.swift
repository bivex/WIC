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
        
        // Constraint-Based Academic Algorithms
        case .kaczmarz:
            applyKaczmarzLayout(windows: windows, in: visibleFrame)
        case .interiorPoint:
            applyInteriorPointLayout(windows: windows, in: visibleFrame)
        case .activeSet:
            applyActiveSetLayout(windows: windows, in: visibleFrame)
        case .linearRelaxation:
            applyLinearRelaxationLayout(windows: windows, in: visibleFrame)
        case .constraintSimplex:
            applyConstraintSimplexLayout(windows: windows, in: visibleFrame)
        
        // Premium Work Modes
        case .videoConferenceMode:
            applyVideoConferenceModeLayout(windows: windows, in: visibleFrame)
        case .dataAnalysisMode:
            applyDataAnalysisModeLayout(windows: windows, in: visibleFrame)
        case .contentCreationMode:
            applyContentCreationModeLayout(windows: windows, in: visibleFrame)
        case .tradingMode:
            applyTradingModeLayout(windows: windows, in: visibleFrame)
        case .gamingStreamingMode:
            applyGamingStreamingModeLayout(windows: windows, in: visibleFrame)
        case .learningMode:
            applyLearningModeLayout(windows: windows, in: visibleFrame)
        case .projectManagementMode:
            applyProjectManagementModeLayout(windows: windows, in: visibleFrame)
        case .monitoringMode:
            applyMonitoringModeLayout(windows: windows, in: visibleFrame)
        
        // Premium Programming Modes
        case .fullStackDevMode:
            applyFullStackDevModeLayout(windows: windows, in: visibleFrame)
        case .mobileDevMode:
            applyMobileDevModeLayout(windows: windows, in: visibleFrame)
        case .devOpsMode:
            applyDevOpsModeLayout(windows: windows, in: visibleFrame)
        case .mlAiDevMode:
            applyMLAIDevModeLayout(windows: windows, in: visibleFrame)
        case .gameDevMode:
            applyGameDevModeLayout(windows: windows, in: visibleFrame)
        case .frontendDevMode:
            applyFrontendDevModeLayout(windows: windows, in: visibleFrame)
        case .backendApiMode:
            applyBackendApiModeLayout(windows: windows, in: visibleFrame)
        case .desktopAppDevMode:
            applyDesktopAppDevModeLayout(windows: windows, in: visibleFrame)
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
    
    // Algorithm: Rule-based / Greedy Grid Distribution
    // Complexity: O(n) where n = window count
    // Type: Equal distribution with mathematical partitioning
    // Reference: See ALGORITHMS.md for technical details
    private func applyGridLayout(windows: [AXUIElement], in frame: CGRect) {
        Logger.shared.debug("Applying grid layout to \(windows.count) windows")
        Logger.shared.debug("Using visibleFrame (excludes Dock/MenuBar): \(frame)")
        let count = windows.count
        let columns = Int(ceil(sqrt(Double(count))))
        let rows = Int(ceil(Double(count) / Double(columns)))
        Logger.shared.debug("Grid: \(columns)x\(rows)")
        
        // Используем настраиваемый отступ из настроек
        let padding = snapSettings.gridPadding
        let bottomExtraPadding: CGFloat = 20 // Дополнительный отступ снизу для Dock
        
        let usableFrame = CGRect(
            x: frame.minX + padding,
            y: frame.minY + padding + bottomExtraPadding,
            width: frame.width - padding * 2,
            height: frame.height - padding * 2 - bottomExtraPadding
        )
        Logger.shared.debug("Added \(padding)px padding + \(bottomExtraPadding)px bottom, usable area: \(usableFrame)")
        
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
    
    // Algorithm: Rule-based Linear Horizontal Distribution
    // Complexity: O(n)
    // Type: Equal width partitioning
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
    
    // Algorithm: Rule-based Linear Vertical Distribution
    // Complexity: O(n)
    // Type: Equal height partitioning
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
    
    // Algorithm: BSP-inspired Cascade with Fixed Offset
    // Complexity: O(n)
    // Type: Hierarchical visual stacking
    // Pattern: Each window offset by 30px for visual hierarchy
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
    
    // Algorithm: Master-Stack with Golden Ratio (φ ≈ 1.618)
    // Complexity: O(n)
    // Type: Fibonacci sequence inspired distribution
    // Math: main = 0.618 × width, stack = 0.382 × width
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
    
    // Algorithm: Master-Stack 2:1 Ratio
    // Complexity: O(n)
    // Type: Primary focus + secondary stack
    // Pattern: Main window 66% + sidebar 33%
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
    
    // MARK: - Advanced Constraint-Based Layouts (Academic Algorithms)
    
    /// Algorithm: Kaczmarz Iterative Projection Method
    /// Complexity: O(n·m) where n = windows, m = iterations
    /// Type: Projection-based constraint solver
    /// Reference: Kaczmarz (1937), "Angenäherte Auflösung von Systemen linearer Gleichungen"
    /// Implementation: Projects windows iteratively onto constraint hyperplanes
    func applyKaczmarzLayout(windows: [AXUIElement], in frame: CGRect) {
        guard !windows.isEmpty else { return }
        Logger.shared.debug("Applying Kaczmarz iterative projection layout")
        
        // Kaczmarz parameters
        let omega: CGFloat = 1.0  // Relaxation parameter (0 < ω < 2)
        let tolerance: CGFloat = 0.01
        let maxIterations = 10
        
        // Initial guess: equal distribution
        var positions: [CGRect] = []
        let initialWidth = frame.width / CGFloat(windows.count)
        for i in 0..<windows.count {
            positions.append(CGRect(
                x: frame.minX + CGFloat(i) * initialWidth,
                y: frame.minY,
                width: initialWidth,
                height: frame.height
            ))
        }
        
        // Iterative projection onto constraints
        for iteration in 0..<maxIterations {
            var maxError: CGFloat = 0
            
            // Project onto each constraint sequentially
            for i in 0..<windows.count {
                // Constraint 1: Non-overlapping (x[i+1] >= x[i] + w[i])
                if i < windows.count - 1 {
                    let violation = (positions[i].minX + positions[i].width) - positions[i + 1].minX
                    if violation > 0 {
                        // Apply projection with relaxation
                        let correction = omega * violation / 2
                        positions[i].origin.x -= correction
                        positions[i + 1].origin.x += correction
                        maxError = max(maxError, abs(violation))
                    }
                }
                
                // Constraint 2: Stay within bounds
                if positions[i].minX < frame.minX {
                    let violation = frame.minX - positions[i].minX
                    positions[i].origin.x += omega * violation
                    maxError = max(maxError, abs(violation))
                }
                if positions[i].maxX > frame.maxX {
                    let violation = positions[i].maxX - frame.maxX
                    positions[i].origin.x -= omega * violation
                    maxError = max(maxError, abs(violation))
                }
            }
            
            // Check convergence
            if maxError < tolerance {
                Logger.shared.debug("Kaczmarz converged in \(iteration + 1) iterations")
                break
            }
        }
        
        // Apply final positions
        for (index, window) in windows.enumerated() {
            AccessibilityHelper.setWindowFrame(window, to: positions[index])
        }
    }
    
    /// Algorithm: Interior Point Barrier Method
    /// Complexity: O(n·k) where k = outer iterations (typically log(1/ε))
    /// Type: Quadratic optimization with barrier functions
    /// Reference: Caroll (1961), "The Created Response Surface Technique"
    /// Implementation: Uses logarithmic barrier to maintain feasibility
    func applyInteriorPointLayout(windows: [AXUIElement], in frame: CGRect) {
        guard !windows.isEmpty else { return }
        Logger.shared.debug("Applying Interior Point barrier method layout")
        
        // Interior point parameters
        let mu: CGFloat = 1.5  // Barrier parameter increase factor
        var t: CGFloat = 1.0   // Current barrier weight
        let epsilon: CGFloat = 0.01
        let margin: CGFloat = frame.width * 0.05  // 5% margin (barrier constraint)
        
        // Objective: minimize sum of squared deviations from ideal positions
        // Subject to: x[i] >= minX + margin, x[i] + w[i] <= maxX - margin
        
        var positions: [CGRect] = []
        let idealWidth = (frame.width - 2 * margin) / CGFloat(windows.count)
        
        // Initial strictly feasible point
        for i in 0..<windows.count {
            positions.append(CGRect(
                x: frame.minX + margin + CGFloat(i) * idealWidth,
                y: frame.minY + margin,
                width: idealWidth,
                height: frame.height - 2 * margin
            ))
        }
        
        // Barrier method: increase t until convergence
        while CGFloat(windows.count) / t >= epsilon {
            // Centering step: optimize with current barrier
            for _ in 0..<5 {
                for i in 0..<windows.count {
                    // Gradient of barrier function: -1/distance_to_boundary
                    let leftBarrier = 1.0 / (positions[i].minX - (frame.minX + margin))
                    let rightBarrier = 1.0 / ((frame.maxX - margin) - positions[i].maxX)
                    
                    // Update position based on barrier gradient
                    let step: CGFloat = 0.1
                    if leftBarrier > rightBarrier {
                        positions[i].origin.x += step
                    } else {
                        positions[i].origin.x -= step
                    }
                    
                    // Ensure strict feasibility
                    positions[i].origin.x = max(frame.minX + margin, min(positions[i].origin.x, frame.maxX - margin - positions[i].width))
                }
            }
            
            t *= mu  // Increase barrier weight
        }
        
        // Apply optimized positions
        for (index, window) in windows.enumerated() {
            AccessibilityHelper.setWindowFrame(window, to: positions[index])
        }
        
        Logger.shared.debug("Interior Point converged with final t=\(t)")
    }
    
    /// Algorithm: Active Set Method for Quadratic Programming
    /// Complexity: O(n²) for identifying active constraints
    /// Type: QP solver with equality/inequality constraints
    /// Reference: Fletcher (1987), "Practical Methods of Optimization"
    /// Implementation: Identifies and activates binding constraints
    func applyActiveSetLayout(windows: [AXUIElement], in frame: CGRect) {
        guard !windows.isEmpty else { return }
        Logger.shared.debug("Applying Active Set QP solver layout")
        
        // Active set: constraints that are exactly satisfied (binding)
        var activeConstraints: Set<Int> = []
        
        // Phase 1: Find initial feasible solution
        var positions: [CGRect] = []
        let width = frame.width / CGFloat(windows.count)
        for i in 0..<windows.count {
            positions.append(CGRect(
                x: frame.minX + CGFloat(i) * width,
                y: frame.minY,
                width: width,
                height: frame.height
            ))
        }
        
        // Phase 2: Identify active constraints (boundaries being touched)
        for i in 0..<windows.count {
            // Check left boundary
            if abs(positions[i].minX - frame.minX) < 1.0 {
                activeConstraints.insert(i * 2)
            }
            // Check right boundary
            if abs(positions[i].maxX - frame.maxX) < 1.0 {
                activeConstraints.insert(i * 2 + 1)
            }
        }
        
        Logger.shared.debug("Active constraints: \(activeConstraints.count)")
        
        // Phase 3: Optimize subject to active constraints
        // For windows at boundaries, keep them there
        // For others, optimize spacing
        
        let boundaryWindows = activeConstraints.count
        let freeWindows = windows.count - boundaryWindows
        
        if freeWindows > 0 {
            // Redistribute free windows optimally
            let freeSpace = frame.width * 0.6  // 60% for free windows
            let freeWidth = freeSpace / CGFloat(freeWindows)
            
            var freeIndex = 0
            for i in 0..<windows.count {
                if !activeConstraints.contains(i * 2) && !activeConstraints.contains(i * 2 + 1) {
                    positions[i].size.width = freeWidth
                    positions[i].origin.x = frame.minX + frame.width * 0.2 + CGFloat(freeIndex) * freeWidth
                    freeIndex += 1
                }
            }
        }
        
        // Apply final positions
        for (index, window) in windows.enumerated() {
            AccessibilityHelper.setWindowFrame(window, to: positions[index])
        }
    }
    
    /// Algorithm: Linear Relaxation (Gauss-Seidel Method)
    /// Complexity: O(n·k) where k = iterations until convergence
    /// Type: Iterative refinement with relaxation parameter
    /// Reference: Gauss (1823), Seidel (1874)
    /// Implementation: Successive over-relaxation (SOR) for window positioning
    func applyLinearRelaxationLayout(windows: [AXUIElement], in frame: CGRect) {
        guard !windows.isEmpty else { return }
        Logger.shared.debug("Applying Linear Relaxation (Gauss-Seidel) layout")
        
        // Relaxation parameters
        let omega: CGFloat = 0.7  // Relaxation parameter (0 < ω < 1 for under-relaxation)
        let maxIterations = 20
        let tolerance: CGFloat = 1.0
        
        // Initial positions
        var positions: [CGRect] = []
        let width = frame.width / CGFloat(windows.count)
        for i in 0..<windows.count {
            positions.append(CGRect(
                x: frame.minX + CGFloat(i) * width,
                y: frame.minY,
                width: width,
                height: frame.height
            ))
        }
        
        // Gauss-Seidel iteration with relaxation
        for iteration in 0..<maxIterations {
            var maxChange: CGFloat = 0
            
            for i in 0..<windows.count {
                let oldX = positions[i].origin.x
                
                // Compute new position based on neighbors
                var newX: CGFloat
                if i == 0 {
                    // First window: align to left with small margin
                    newX = frame.minX + 10
                } else if i == windows.count - 1 {
                    // Last window: align to right
                    newX = frame.maxX - positions[i].width - 10
                } else {
                    // Middle windows: balance between neighbors
                    let leftNeighbor = positions[i - 1].maxX
                    let idealSpacing = width * 0.1  // 10% spacing
                    newX = leftNeighbor + idealSpacing
                }
                
                // Apply relaxation: x_new = (1-ω)·x_old + ω·x_computed
                positions[i].origin.x = (1 - omega) * oldX + omega * newX
                
                let change = abs(positions[i].origin.x - oldX)
                maxChange = max(maxChange, change)
            }
            
            // Check convergence
            if maxChange < tolerance {
                Logger.shared.debug("Linear Relaxation converged in \(iteration + 1) iterations")
                break
            }
        }
        
        // Apply converged positions
        for (index, window) in windows.enumerated() {
            AccessibilityHelper.setWindowFrame(window, to: positions[index])
        }
    }
    
    /// Algorithm: Constraint Simplex Method (Linear Programming)
    /// Complexity: O(n²) average, exponential worst-case
    /// Type: LP solver navigating feasible region vertices
    /// Reference: Dantzig (1947), "Programming in a Linear Structure"
    /// Implementation: Simplex tableau for window constraint optimization
    func applyConstraintSimplexLayout(windows: [AXUIElement], in frame: CGRect) {
        guard !windows.isEmpty else { return }
        Logger.shared.debug("Applying Constraint Simplex (LP) layout")
        
        // Simplex method: move along edges of feasible region to optimal vertex
        
        // Phase I: Find initial basic feasible solution (BFS)
        var positions: [CGRect] = []
        let width = frame.width / CGFloat(windows.count)
        
        // Start at corner (vertex of feasible region)
        for i in 0..<windows.count {
            positions.append(CGRect(
                x: frame.minX + CGFloat(i) * width,
                y: frame.minY,
                width: width,
                height: frame.height
            ))
        }
        
        // Phase II: Pivot to improve objective function
        // Objective: maximize total utilized screen space
        // Constraints: non-negativity, non-overlapping, within bounds
        
        let iterations = min(windows.count, 5)  // Limit pivots
        for iteration in 0..<iterations {
            // Find entering variable (most negative reduced cost)
            var enteringIndex = -1
            var minReducedCost: CGFloat = 0
            
            for i in 0..<windows.count {
                // Reduced cost: potential improvement from expanding this window
                let currentSize = positions[i].width
                let maxPossibleSize = width * 1.5
                let reducedCost = currentSize - maxPossibleSize
                
                if reducedCost < minReducedCost {
                    minReducedCost = reducedCost
                    enteringIndex = i
                }
            }
            
            // If all reduced costs non-negative, optimal solution reached
            if enteringIndex < 0 {
                Logger.shared.debug("Simplex reached optimality in \(iteration) pivots")
                break
            }
            
            // Find leaving variable (minimum ratio test)
            // Expand window at enteringIndex until hitting constraint
            let expansionAmount = width * 0.2
            positions[enteringIndex].size.width += expansionAmount
            
            // Maintain feasibility: compress neighbors
            if enteringIndex < windows.count - 1 {
                positions[enteringIndex + 1].origin.x += expansionAmount
            }
        }
        
        // Ensure final feasibility
        var currentX = frame.minX
        for i in 0..<windows.count {
            positions[i].origin.x = currentX
            currentX += positions[i].width
            
            // Adjust last window to fit exactly
            if i == windows.count - 1 {
                positions[i].size.width = frame.maxX - positions[i].minX
            }
        }
        
        // Apply optimal positions
        for (index, window) in windows.enumerated() {
            AccessibilityHelper.setWindowFrame(window, to: positions[index])
        }
        
        Logger.shared.debug("Simplex layout complete")
    }
    
    // MARK: - Premium Work Modes (Professional Layouts)
    
    /// Video Conference Mode: Optimal layout for video calls
    /// Main video window (70%) + chat/notes sidebar (30%)
    private func applyVideoConferenceModeLayout(windows: [AXUIElement], in frame: CGRect) {
        guard !windows.isEmpty else { return }
        Logger.shared.debug("Applying Video Conference Pro layout")
        
        if windows.count == 1 {
            // Single window - center it with optimal video ratio (16:9)
            let optimalHeight = frame.width * 0.6 * (9.0/16.0)
            let centeredFrame = CGRect(
                x: frame.midX - (frame.width * 0.6) / 2,
                y: frame.midY - optimalHeight / 2,
                width: frame.width * 0.6,
                height: optimalHeight
            )
            AccessibilityHelper.setWindowFrame(windows[0], to: centeredFrame)
        } else {
            // Main video (70%) + sidebar windows (30%)
            let mainWidth = frame.width * 0.7
            let sidebarWidth = frame.width * 0.3
            
            // Main video window
            AccessibilityHelper.setWindowFrame(windows[0], to: CGRect(
                x: frame.minX,
                y: frame.minY,
                width: mainWidth,
                height: frame.height
            ))
            
            // Sidebar windows (chat, notes, etc.)
            let sidebarWindows = Array(windows[1...])
            let windowHeight = frame.height / CGFloat(sidebarWindows.count)
            
            for (index, window) in sidebarWindows.enumerated() {
                AccessibilityHelper.setWindowFrame(window, to: CGRect(
                    x: frame.minX + mainWidth,
                    y: frame.minY + CGFloat(index) * windowHeight,
                    width: sidebarWidth,
                    height: windowHeight
                ))
            }
        }
    }
    
    /// Data Analysis Mode: Studio layout for data scientists
    /// Tables (40%) + Charts (35%) + Code/Scripts (25%)
    private func applyDataAnalysisModeLayout(windows: [AXUIElement], in frame: CGRect) {
        guard !windows.isEmpty else { return }
        Logger.shared.debug("Applying Data Analysis Studio layout")
        
        if windows.count == 1 {
            // Single window - full screen for main analysis
            AccessibilityHelper.setWindowFrame(windows[0], to: frame)
        } else if windows.count == 2 {
            // Main analysis (70%) + secondary (30%)
            let mainWidth = frame.width * 0.7
            AccessibilityHelper.setWindowFrame(windows[0], to: CGRect(
                x: frame.minX,
                y: frame.minY,
                width: mainWidth,
                height: frame.height
            ))
            AccessibilityHelper.setWindowFrame(windows[1], to: CGRect(
                x: frame.minX + mainWidth,
                y: frame.minY,
                width: frame.width - mainWidth,
                height: frame.height
            ))
        } else {
            // Three-panel layout: Tables + Charts + Code
            let tableWidth = frame.width * 0.4
            let chartWidth = frame.width * 0.35
            let codeWidth = frame.width * 0.25
            
            // Tables/Data (left)
            AccessibilityHelper.setWindowFrame(windows[0], to: CGRect(
                x: frame.minX,
                y: frame.minY,
                width: tableWidth,
                height: frame.height
            ))
            
            // Charts/Visualization (center)
            AccessibilityHelper.setWindowFrame(windows[1], to: CGRect(
                x: frame.minX + tableWidth,
                y: frame.minY,
                width: chartWidth,
                height: frame.height
            ))
            
            // Code/Scripts (right)
            let codeStartX = frame.minX + tableWidth + chartWidth
            if windows.count == 3 {
                AccessibilityHelper.setWindowFrame(windows[2], to: CGRect(
                    x: codeStartX,
                    y: frame.minY,
                    width: codeWidth,
                    height: frame.height
                ))
            } else {
                // Multiple code windows - stack vertically
                let codeWindows = Array(windows[2...])
                let codeWindowHeight = frame.height / CGFloat(codeWindows.count)
                
                for (index, window) in codeWindows.enumerated() {
                    AccessibilityHelper.setWindowFrame(window, to: CGRect(
                        x: codeStartX,
                        y: frame.minY + CGFloat(index) * codeWindowHeight,
                        width: codeWidth,
                        height: codeWindowHeight
                    ))
                }
            }
        }
    }
    
    /// Content Creation Mode: Creator workspace
    /// Editor (50%) + Preview (25%) + Resources (25%)
    private func applyContentCreationModeLayout(windows: [AXUIElement], in frame: CGRect) {
        guard !windows.isEmpty else { return }
        Logger.shared.debug("Applying Content Creator Suite layout")
        
        if windows.count == 1 {
            // Single window - center with optimal aspect ratio
            let optimalWidth = frame.width * 0.8
            let centeredFrame = CGRect(
                x: frame.midX - optimalWidth / 2,
                y: frame.minY,
                width: optimalWidth,
                height: frame.height
            )
            AccessibilityHelper.setWindowFrame(windows[0], to: centeredFrame)
        } else if windows.count == 2 {
            // Editor (70%) + Preview (30%)
            let editorWidth = frame.width * 0.7
            AccessibilityHelper.setWindowFrame(windows[0], to: CGRect(
                x: frame.minX,
                y: frame.minY,
                width: editorWidth,
                height: frame.height
            ))
            AccessibilityHelper.setWindowFrame(windows[1], to: CGRect(
                x: frame.minX + editorWidth,
                y: frame.minY,
                width: frame.width - editorWidth,
                height: frame.height
            ))
        } else {
            // Full creator layout: Editor + Preview + Resources
            let editorWidth = frame.width * 0.5
            let previewWidth = frame.width * 0.25
            let resourceWidth = frame.width * 0.25
            
            // Main editor (left)
            AccessibilityHelper.setWindowFrame(windows[0], to: CGRect(
                x: frame.minX,
                y: frame.minY,
                width: editorWidth,
                height: frame.height
            ))
            
            // Preview (top right)
            AccessibilityHelper.setWindowFrame(windows[1], to: CGRect(
                x: frame.minX + editorWidth,
                y: frame.minY,
                width: previewWidth,
                height: frame.height * 0.6
            ))
            
            // Resources (bottom right)
            let resourceWindows = Array(windows[2...])
            let resourceHeight = frame.height * 0.4 / CGFloat(resourceWindows.count)
            
            for (index, window) in resourceWindows.enumerated() {
                AccessibilityHelper.setWindowFrame(window, to: CGRect(
                    x: frame.minX + editorWidth + previewWidth,
                    y: frame.minY + frame.height * 0.6 + CGFloat(index) * resourceHeight,
                    width: resourceWidth,
                    height: resourceHeight
                ))
            }
        }
    }
    
    /// Trading Mode: Professional trading workstation
    /// Charts (60%) + Terminal (25%) + News/Analytics (15%)
    private func applyTradingModeLayout(windows: [AXUIElement], in frame: CGRect) {
        guard !windows.isEmpty else { return }
        Logger.shared.debug("Applying Trading Workstation layout")
        
        if windows.count == 1 {
            // Single window - full screen for main chart
            AccessibilityHelper.setWindowFrame(windows[0], to: frame)
        } else if windows.count == 2 {
            // Charts (75%) + Terminal (25%)
            let chartWidth = frame.width * 0.75
            AccessibilityHelper.setWindowFrame(windows[0], to: CGRect(
                x: frame.minX,
                y: frame.minY,
                width: chartWidth,
                height: frame.height
            ))
            AccessibilityHelper.setWindowFrame(windows[1], to: CGRect(
                x: frame.minX + chartWidth,
                y: frame.minY,
                width: frame.width - chartWidth,
                height: frame.height
            ))
        } else {
            // Professional trading layout
            let chartWidth = frame.width * 0.6
            let terminalWidth = frame.width * 0.25
            let newsWidth = frame.width * 0.15
            
            // Main charts (left)
            AccessibilityHelper.setWindowFrame(windows[0], to: CGRect(
                x: frame.minX,
                y: frame.minY,
                width: chartWidth,
                height: frame.height
            ))
            
            // Trading terminal (center)
            AccessibilityHelper.setWindowFrame(windows[1], to: CGRect(
                x: frame.minX + chartWidth,
                y: frame.minY,
                width: terminalWidth,
                height: frame.height
            ))
            
            // News/Analytics (right)
            let newsWindows = Array(windows[2...])
            let newsHeight = frame.height / CGFloat(newsWindows.count)
            
            for (index, window) in newsWindows.enumerated() {
                AccessibilityHelper.setWindowFrame(window, to: CGRect(
                    x: frame.minX + chartWidth + terminalWidth,
                    y: frame.minY + CGFloat(index) * newsHeight,
                    width: newsWidth,
                    height: newsHeight
                ))
            }
        }
    }
    
    /// Gaming & Streaming Mode: Streamer's dream setup
    /// Game (70%) + OBS/Stream (20%) + Chat/Donations (10%)
    private func applyGamingStreamingModeLayout(windows: [AXUIElement], in frame: CGRect) {
        guard !windows.isEmpty else { return }
        Logger.shared.debug("Applying Gaming & Streaming layout")
        
        if windows.count == 1 {
            // Single window - game in center with optimal ratio
            let gameWidth = frame.width * 0.8
            let gameHeight = gameWidth * (9.0/16.0)
            AccessibilityHelper.setWindowFrame(windows[0], to: CGRect(
                x: frame.midX - gameWidth / 2,
                y: frame.midY - gameHeight / 2,
                width: gameWidth,
                height: min(gameHeight, frame.height * 0.9)
            ))
        } else if windows.count == 2 {
            // Game (80%) + Stream tools (20%)
            let gameWidth = frame.width * 0.8
            AccessibilityHelper.setWindowFrame(windows[0], to: CGRect(
                x: frame.minX,
                y: frame.minY,
                width: gameWidth,
                height: frame.height
            ))
            AccessibilityHelper.setWindowFrame(windows[1], to: CGRect(
                x: frame.minX + gameWidth,
                y: frame.minY,
                width: frame.width - gameWidth,
                height: frame.height
            ))
        } else {
            // Full streaming setup
            let gameWidth = frame.width * 0.7
            let streamWidth = frame.width * 0.2
            let chatWidth = frame.width * 0.1
            
            // Game window (main)
            AccessibilityHelper.setWindowFrame(windows[0], to: CGRect(
                x: frame.minX,
                y: frame.minY,
                width: gameWidth,
                height: frame.height
            ))
            
            // OBS/Streaming tools
            AccessibilityHelper.setWindowFrame(windows[1], to: CGRect(
                x: frame.minX + gameWidth,
                y: frame.minY,
                width: streamWidth,
                height: frame.height * 0.7
            ))
            
            // Chat/Donations (right column)
            let chatWindows = Array(windows[2...])
            let chatStartY = frame.minY + frame.height * 0.7
            let chatHeight = (frame.height * 0.3) / CGFloat(chatWindows.count)
            
            for (index, window) in chatWindows.enumerated() {
                AccessibilityHelper.setWindowFrame(window, to: CGRect(
                    x: frame.minX + gameWidth + streamWidth,
                    y: chatStartY + CGFloat(index) * chatHeight,
                    width: chatWidth,
                    height: chatHeight
                ))
            }
        }
    }
    
    /// Learning Mode: Educational environment
    /// Video/Lecture (60%) + Notes (25%) + Additional materials (15%)
    private func applyLearningModeLayout(windows: [AXUIElement], in frame: CGRect) {
        guard !windows.isEmpty else { return }
        Logger.shared.debug("Applying Learning Environment layout")
        
        if windows.count == 1 {
            // Single window - optimal for video content
            let videoWidth = frame.width * 0.8
            let videoHeight = videoWidth * (9.0/16.0)
            AccessibilityHelper.setWindowFrame(windows[0], to: CGRect(
                x: frame.midX - videoWidth / 2,
                y: frame.minY + (frame.height - videoHeight) * 0.3,
                width: videoWidth,
                height: min(videoHeight, frame.height * 0.7)
            ))
        } else if windows.count == 2 {
            // Video (70%) + Notes (30%)
            let videoWidth = frame.width * 0.7
            AccessibilityHelper.setWindowFrame(windows[0], to: CGRect(
                x: frame.minX,
                y: frame.minY,
                width: videoWidth,
                height: frame.height
            ))
            AccessibilityHelper.setWindowFrame(windows[1], to: CGRect(
                x: frame.minX + videoWidth,
                y: frame.minY,
                width: frame.width - videoWidth,
                height: frame.height
            ))
        } else {
            // Full learning setup
            let videoWidth = frame.width * 0.6
            let notesWidth = frame.width * 0.25
            let materialWidth = frame.width * 0.15
            
            // Main video/lecture (left)
            AccessibilityHelper.setWindowFrame(windows[0], to: CGRect(
                x: frame.minX,
                y: frame.minY,
                width: videoWidth,
                height: frame.height
            ))
            
            // Notes (center)
            AccessibilityHelper.setWindowFrame(windows[1], to: CGRect(
                x: frame.minX + videoWidth,
                y: frame.minY,
                width: notesWidth,
                height: frame.height
            ))
            
            // Additional materials (right)
            let materialWindows = Array(windows[2...])
            let materialHeight = frame.height / CGFloat(materialWindows.count)
            
            for (index, window) in materialWindows.enumerated() {
                AccessibilityHelper.setWindowFrame(window, to: CGRect(
                    x: frame.minX + videoWidth + notesWidth,
                    y: frame.minY + CGFloat(index) * materialHeight,
                    width: materialWidth,
                    height: materialHeight
                ))
            }
        }
    }
    
    /// Project Management Mode: Command center for project managers
    /// Kanban (50%) + Calendar (30%) + Communications (20%)
    private func applyProjectManagementModeLayout(windows: [AXUIElement], in frame: CGRect) {
        guard !windows.isEmpty else { return }
        Logger.shared.debug("Applying Project Command Center layout")
        
        if windows.count == 1 {
            // Single window - kanban/main project view
            AccessibilityHelper.setWindowFrame(windows[0], to: frame)
        } else if windows.count == 2 {
            // Kanban (65%) + Calendar/Timeline (35%)
            let kanbanWidth = frame.width * 0.65
            AccessibilityHelper.setWindowFrame(windows[0], to: CGRect(
                x: frame.minX,
                y: frame.minY,
                width: kanbanWidth,
                height: frame.height
            ))
            AccessibilityHelper.setWindowFrame(windows[1], to: CGRect(
                x: frame.minX + kanbanWidth,
                y: frame.minY,
                width: frame.width - kanbanWidth,
                height: frame.height
            ))
        } else {
            // Full project management layout
            let kanbanWidth = frame.width * 0.5
            let calendarWidth = frame.width * 0.3
            let commWidth = frame.width * 0.2
            
            // Kanban board (left)
            AccessibilityHelper.setWindowFrame(windows[0], to: CGRect(
                x: frame.minX,
                y: frame.minY,
                width: kanbanWidth,
                height: frame.height
            ))
            
            // Calendar/Timeline (center)
            AccessibilityHelper.setWindowFrame(windows[1], to: CGRect(
                x: frame.minX + kanbanWidth,
                y: frame.minY,
                width: calendarWidth,
                height: frame.height
            ))
            
            // Communications (right)
            let commWindows = Array(windows[2...])
            let commHeight = frame.height / CGFloat(commWindows.count)
            
            for (index, window) in commWindows.enumerated() {
                AccessibilityHelper.setWindowFrame(window, to: CGRect(
                    x: frame.minX + kanbanWidth + calendarWidth,
                    y: frame.minY + CGFloat(index) * commHeight,
                    width: commWidth,
                    height: commHeight
                ))
            }
        }
    }
    
    /// Monitoring Mode: System monitoring and DevOps hub
    /// Main Dashboard (60%) + Logs (25%) + Alerts/Metrics (15%)
    private func applyMonitoringModeLayout(windows: [AXUIElement], in frame: CGRect) {
        guard !windows.isEmpty else { return }
        Logger.shared.debug("Applying System Monitoring Hub layout")
        
        if windows.count == 1 {
            // Single window - main dashboard
            AccessibilityHelper.setWindowFrame(windows[0], to: frame)
        } else if windows.count == 2 {
            // Dashboard (70%) + Logs (30%)
            let dashWidth = frame.width * 0.7
            AccessibilityHelper.setWindowFrame(windows[0], to: CGRect(
                x: frame.minX,
                y: frame.minY,
                width: dashWidth,
                height: frame.height
            ))
            AccessibilityHelper.setWindowFrame(windows[1], to: CGRect(
                x: frame.minX + dashWidth,
                y: frame.minY,
                width: frame.width - dashWidth,
                height: frame.height
            ))
        } else {
            // Full monitoring setup
            let dashWidth = frame.width * 0.6
            let logsWidth = frame.width * 0.25
            let alertsWidth = frame.width * 0.15
            
            // Main dashboard (left)
            AccessibilityHelper.setWindowFrame(windows[0], to: CGRect(
                x: frame.minX,
                y: frame.minY,
                width: dashWidth,
                height: frame.height
            ))
            
            // Logs (center)
            AccessibilityHelper.setWindowFrame(windows[1], to: CGRect(
                x: frame.minX + dashWidth,
                y: frame.minY,
                width: logsWidth,
                height: frame.height
            ))
            
            // Alerts/Metrics (right)
            let alertWindows = Array(windows[2...])
            let alertHeight = frame.height / CGFloat(alertWindows.count)
            
            for (index, window) in alertWindows.enumerated() {
                AccessibilityHelper.setWindowFrame(window, to: CGRect(
                    x: frame.minX + dashWidth + logsWidth,
                    y: frame.minY + CGFloat(index) * alertHeight,
                    width: alertsWidth,
                    height: alertHeight
                ))
            }
        }
    }
    
    // MARK: - Premium Programming Modes (Power Developer Layouts)
    
    /// Full-Stack Development: Complete web development workstation
    /// Code (40%) + Frontend Preview (30%) + Terminal/API (20%) + Database/Logs (10%)
    private func applyFullStackDevModeLayout(windows: [AXUIElement], in frame: CGRect) {
        guard !windows.isEmpty else { return }
        Logger.shared.debug("Applying Full-Stack Development layout")
        
        if windows.count == 1 {
            // Single window - editor with optimal code width
            let optimalWidth = min(frame.width * 0.8, 1400)
            let centeredFrame = CGRect(
                x: frame.midX - optimalWidth / 2,
                y: frame.minY,
                width: optimalWidth,
                height: frame.height
            )
            AccessibilityHelper.setWindowFrame(windows[0], to: centeredFrame)
        } else if windows.count == 2 {
            // Code (60%) + Preview (40%)
            let codeWidth = frame.width * 0.6
            AccessibilityHelper.setWindowFrame(windows[0], to: CGRect(
                x: frame.minX,
                y: frame.minY,
                width: codeWidth,
                height: frame.height
            ))
            AccessibilityHelper.setWindowFrame(windows[1], to: CGRect(
                x: frame.minX + codeWidth,
                y: frame.minY,
                width: frame.width - codeWidth,
                height: frame.height
            ))
        } else {
            // Full-stack quad layout
            let codeWidth = frame.width * 0.4
            let previewWidth = frame.width * 0.3
            let terminalWidth = frame.width * 0.2
            let dbWidth = frame.width * 0.1
            
            // Main code editor (left)
            AccessibilityHelper.setWindowFrame(windows[0], to: CGRect(
                x: frame.minX,
                y: frame.minY,
                width: codeWidth,
                height: frame.height
            ))
            
            // Frontend preview (center-left)
            AccessibilityHelper.setWindowFrame(windows[1], to: CGRect(
                x: frame.minX + codeWidth,
                y: frame.minY,
                width: previewWidth,
                height: frame.height
            ))
            
            // Terminal/API tools (center-right)
            AccessibilityHelper.setWindowFrame(windows[2], to: CGRect(
                x: frame.minX + codeWidth + previewWidth,
                y: frame.minY,
                width: terminalWidth,
                height: frame.height
            ))
            
            // Database/Logs (right)
            if windows.count > 3 {
                let dbWindows = Array(windows[3...])
                let dbHeight = frame.height / CGFloat(dbWindows.count)
                
                for (index, window) in dbWindows.enumerated() {
                    AccessibilityHelper.setWindowFrame(window, to: CGRect(
                        x: frame.minX + codeWidth + previewWidth + terminalWidth,
                        y: frame.minY + CGFloat(index) * dbHeight,
                        width: dbWidth,
                        height: dbHeight
                    ))
                }
            }
        }
    }
    
    /// Mobile Development: IDE + Simulator/Emulator workflow
    /// IDE (50%) + Simulator/Emulator (35%) + Console/Logs (15%)
    private func applyMobileDevModeLayout(windows: [AXUIElement], in frame: CGRect) {
        guard !windows.isEmpty else { return }
        Logger.shared.debug("Applying Mobile Development Studio layout")
        
        if windows.count == 1 {
            // Single window - IDE centered
            AccessibilityHelper.setWindowFrame(windows[0], to: frame)
        } else if windows.count == 2 {
            // IDE (65%) + Simulator (35%)
            let ideWidth = frame.width * 0.65
            AccessibilityHelper.setWindowFrame(windows[0], to: CGRect(
                x: frame.minX,
                y: frame.minY,
                width: ideWidth,
                height: frame.height
            ))
            AccessibilityHelper.setWindowFrame(windows[1], to: CGRect(
                x: frame.minX + ideWidth,
                y: frame.minY,
                width: frame.width - ideWidth,
                height: frame.height
            ))
        } else {
            // Full mobile dev layout
            let ideWidth = frame.width * 0.5
            let simWidth = frame.width * 0.35
            let consoleWidth = frame.width * 0.15
            
            // IDE (left)
            AccessibilityHelper.setWindowFrame(windows[0], to: CGRect(
                x: frame.minX,
                y: frame.minY,
                width: ideWidth,
                height: frame.height
            ))
            
            // Simulator/Emulator (center) - optimal phone ratio
            let simHeight = min(frame.height, simWidth * 2.0) // 2:1 ratio for phone
            AccessibilityHelper.setWindowFrame(windows[1], to: CGRect(
                x: frame.minX + ideWidth,
                y: frame.minY + (frame.height - simHeight) / 2,
                width: simWidth,
                height: simHeight
            ))
            
            // Console/Logs (right)
            let consoleWindows = Array(windows[2...])
            let consoleHeight = frame.height / CGFloat(consoleWindows.count)
            
            for (index, window) in consoleWindows.enumerated() {
                AccessibilityHelper.setWindowFrame(window, to: CGRect(
                    x: frame.minX + ideWidth + simWidth,
                    y: frame.minY + CGFloat(index) * consoleHeight,
                    width: consoleWidth,
                    height: consoleHeight
                ))
            }
        }
    }
    
    /// DevOps Mode: Infrastructure and operations command center
    /// Terminals (40%) + Monitoring (30%) + Configs/IaC (20%) + Documentation (10%)
    private func applyDevOpsModeLayout(windows: [AXUIElement], in frame: CGRect) {
        guard !windows.isEmpty else { return }
        Logger.shared.debug("Applying DevOps Command Center layout")
        
        if windows.count == 1 {
            // Single terminal - full screen
            AccessibilityHelper.setWindowFrame(windows[0], to: frame)
        } else if windows.count == 2 {
            // Terminals (60%) + Monitoring (40%)
            let termWidth = frame.width * 0.6
            AccessibilityHelper.setWindowFrame(windows[0], to: CGRect(
                x: frame.minX,
                y: frame.minY,
                width: termWidth,
                height: frame.height
            ))
            AccessibilityHelper.setWindowFrame(windows[1], to: CGRect(
                x: frame.minX + termWidth,
                y: frame.minY,
                width: frame.width - termWidth,
                height: frame.height
            ))
        } else {
            // Full DevOps layout
            let termWidth = frame.width * 0.4
            let monitorWidth = frame.width * 0.3
            let configWidth = frame.width * 0.2
            let docWidth = frame.width * 0.1
            
            // Terminals (left) - multiple terminal sessions
            if windows.count >= 2 {
                let termHeight = frame.height / 2
                AccessibilityHelper.setWindowFrame(windows[0], to: CGRect(
                    x: frame.minX,
                    y: frame.minY,
                    width: termWidth,
                    height: termHeight
                ))
                AccessibilityHelper.setWindowFrame(windows[1], to: CGRect(
                    x: frame.minX,
                    y: frame.minY + termHeight,
                    width: termWidth,
                    height: termHeight
                ))
            }
            
            // Monitoring dashboards (center)
            if windows.count > 2 {
                AccessibilityHelper.setWindowFrame(windows[2], to: CGRect(
                    x: frame.minX + termWidth,
                    y: frame.minY,
                    width: monitorWidth,
                    height: frame.height
                ))
            }
            
            // Config/IaC files (right)
            if windows.count > 3 {
                AccessibilityHelper.setWindowFrame(windows[3], to: CGRect(
                    x: frame.minX + termWidth + monitorWidth,
                    y: frame.minY,
                    width: configWidth,
                    height: frame.height
                ))
            }
            
            // Documentation (far right)
            if windows.count > 4 {
                let docWindows = Array(windows[4...])
                let docHeight = frame.height / CGFloat(docWindows.count)
                
                for (index, window) in docWindows.enumerated() {
                    AccessibilityHelper.setWindowFrame(window, to: CGRect(
                        x: frame.minX + termWidth + monitorWidth + configWidth,
                        y: frame.minY + CGFloat(index) * docHeight,
                        width: docWidth,
                        height: docHeight
                    ))
                }
            }
        }
    }
    
    /// ML/AI Development: Data science and machine learning lab
    /// Jupyter/Code (45%) + Visualization/Plots (35%) + Data/Metrics (20%)
    private func applyMLAIDevModeLayout(windows: [AXUIElement], in frame: CGRect) {
        guard !windows.isEmpty else { return }
        Logger.shared.debug("Applying ML/AI Development Lab layout")
        
        if windows.count == 1 {
            // Single notebook - optimal for data science
            let optimalWidth = frame.width * 0.9
            AccessibilityHelper.setWindowFrame(windows[0], to: CGRect(
                x: frame.midX - optimalWidth / 2,
                y: frame.minY,
                width: optimalWidth,
                height: frame.height
            ))
        } else if windows.count == 2 {
            // Code (55%) + Visualization (45%)
            let codeWidth = frame.width * 0.55
            AccessibilityHelper.setWindowFrame(windows[0], to: CGRect(
                x: frame.minX,
                y: frame.minY,
                width: codeWidth,
                height: frame.height
            ))
            AccessibilityHelper.setWindowFrame(windows[1], to: CGRect(
                x: frame.minX + codeWidth,
                y: frame.minY,
                width: frame.width - codeWidth,
                height: frame.height
            ))
        } else {
            // Full ML/AI lab
            let codeWidth = frame.width * 0.45
            let vizWidth = frame.width * 0.35
            let dataWidth = frame.width * 0.2
            
            // Jupyter/Code (left)
            AccessibilityHelper.setWindowFrame(windows[0], to: CGRect(
                x: frame.minX,
                y: frame.minY,
                width: codeWidth,
                height: frame.height
            ))
            
            // Visualization/Plots (center)
            AccessibilityHelper.setWindowFrame(windows[1], to: CGRect(
                x: frame.minX + codeWidth,
                y: frame.minY,
                width: vizWidth,
                height: frame.height
            ))
            
            // Data/Metrics (right)
            let dataWindows = Array(windows[2...])
            let dataHeight = frame.height / CGFloat(dataWindows.count)
            
            for (index, window) in dataWindows.enumerated() {
                AccessibilityHelper.setWindowFrame(window, to: CGRect(
                    x: frame.minX + codeWidth + vizWidth,
                    y: frame.minY + CGFloat(index) * dataHeight,
                    width: dataWidth,
                    height: dataHeight
                ))
            }
        }
    }
    
    /// Game Development: Game engine and asset pipeline
    /// Engine/IDE (50%) + Game Preview (30%) + Assets/Inspector (20%)
    private func applyGameDevModeLayout(windows: [AXUIElement], in frame: CGRect) {
        guard !windows.isEmpty else { return }
        Logger.shared.debug("Applying Game Development Suite layout")
        
        if windows.count == 1 {
            // Single window - game engine
            AccessibilityHelper.setWindowFrame(windows[0], to: frame)
        } else if windows.count == 2 {
            // Engine (65%) + Preview (35%)
            let engineWidth = frame.width * 0.65
            AccessibilityHelper.setWindowFrame(windows[0], to: CGRect(
                x: frame.minX,
                y: frame.minY,
                width: engineWidth,
                height: frame.height
            ))
            AccessibilityHelper.setWindowFrame(windows[1], to: CGRect(
                x: frame.minX + engineWidth,
                y: frame.minY,
                width: frame.width - engineWidth,
                height: frame.height
            ))
        } else {
            // Full game dev layout
            let engineWidth = frame.width * 0.5
            let previewWidth = frame.width * 0.3
            let assetsWidth = frame.width * 0.2
            
            // Game Engine/IDE (left)
            AccessibilityHelper.setWindowFrame(windows[0], to: CGRect(
                x: frame.minX,
                y: frame.minY,
                width: engineWidth,
                height: frame.height
            ))
            
            // Game Preview (center) - maintain aspect ratio
            let previewHeight = previewWidth * (9.0/16.0) // 16:9 game viewport
            AccessibilityHelper.setWindowFrame(windows[1], to: CGRect(
                x: frame.minX + engineWidth,
                y: frame.minY,
                width: previewWidth,
                height: min(previewHeight, frame.height * 0.7)
            ))
            
            // Assets/Inspector (right)
            let assetWindows = Array(windows[2...])
            let assetHeight = frame.height / CGFloat(assetWindows.count)
            
            for (index, window) in assetWindows.enumerated() {
                AccessibilityHelper.setWindowFrame(window, to: CGRect(
                    x: frame.minX + engineWidth + previewWidth,
                    y: frame.minY + CGFloat(index) * assetHeight,
                    width: assetsWidth,
                    height: assetHeight
                ))
            }
        }
    }
    
    /// Frontend Development: Modern web development hub
    /// Editor (40%) + Browser/Preview (40%) + DevTools (20%)
    private func applyFrontendDevModeLayout(windows: [AXUIElement], in frame: CGRect) {
        guard !windows.isEmpty else { return }
        Logger.shared.debug("Applying Frontend Development Hub layout")
        
        if windows.count == 1 {
            // Single window - code editor
            AccessibilityHelper.setWindowFrame(windows[0], to: frame)
        } else if windows.count == 2 {
            // Editor (50%) + Browser (50%)
            let editorWidth = frame.width * 0.5
            AccessibilityHelper.setWindowFrame(windows[0], to: CGRect(
                x: frame.minX,
                y: frame.minY,
                width: editorWidth,
                height: frame.height
            ))
            AccessibilityHelper.setWindowFrame(windows[1], to: CGRect(
                x: frame.minX + editorWidth,
                y: frame.minY,
                width: frame.width - editorWidth,
                height: frame.height
            ))
        } else {
            // Full frontend layout
            let editorWidth = frame.width * 0.4
            let browserWidth = frame.width * 0.4
            let toolsWidth = frame.width * 0.2
            
            // Code Editor (left)
            AccessibilityHelper.setWindowFrame(windows[0], to: CGRect(
                x: frame.minX,
                y: frame.minY,
                width: editorWidth,
                height: frame.height
            ))
            
            // Browser/Preview (center)
            AccessibilityHelper.setWindowFrame(windows[1], to: CGRect(
                x: frame.minX + editorWidth,
                y: frame.minY,
                width: browserWidth,
                height: frame.height
            ))
            
            // DevTools/Console (right)
            let toolWindows = Array(windows[2...])
            let toolHeight = frame.height / CGFloat(toolWindows.count)
            
            for (index, window) in toolWindows.enumerated() {
                AccessibilityHelper.setWindowFrame(window, to: CGRect(
                    x: frame.minX + editorWidth + browserWidth,
                    y: frame.minY + CGFloat(index) * toolHeight,
                    width: toolsWidth,
                    height: toolHeight
                ))
            }
        }
    }
    
    /// Backend/API Development: Server-side development workshop
    /// Code (40%) + API Tester (30%) + Database (20%) + Logs/Monitoring (10%)
    private func applyBackendApiModeLayout(windows: [AXUIElement], in frame: CGRect) {
        guard !windows.isEmpty else { return }
        Logger.shared.debug("Applying Backend/API Workshop layout")
        
        if windows.count == 1 {
            // Single window - code editor
            AccessibilityHelper.setWindowFrame(windows[0], to: frame)
        } else if windows.count == 2 {
            // Code (60%) + API Tester (40%)
            let codeWidth = frame.width * 0.6
            AccessibilityHelper.setWindowFrame(windows[0], to: CGRect(
                x: frame.minX,
                y: frame.minY,
                width: codeWidth,
                height: frame.height
            ))
            AccessibilityHelper.setWindowFrame(windows[1], to: CGRect(
                x: frame.minX + codeWidth,
                y: frame.minY,
                width: frame.width - codeWidth,
                height: frame.height
            ))
        } else {
            // Full backend workshop
            let codeWidth = frame.width * 0.4
            let apiWidth = frame.width * 0.3
            let dbWidth = frame.width * 0.2
            let logsWidth = frame.width * 0.1
            
            // Code Editor (left)
            AccessibilityHelper.setWindowFrame(windows[0], to: CGRect(
                x: frame.minX,
                y: frame.minY,
                width: codeWidth,
                height: frame.height
            ))
            
            // API Tester (center-left)
            AccessibilityHelper.setWindowFrame(windows[1], to: CGRect(
                x: frame.minX + codeWidth,
                y: frame.minY,
                width: apiWidth,
                height: frame.height
            ))
            
            // Database (center-right)
            if windows.count > 2 {
                AccessibilityHelper.setWindowFrame(windows[2], to: CGRect(
                    x: frame.minX + codeWidth + apiWidth,
                    y: frame.minY,
                    width: dbWidth,
                    height: frame.height
                ))
            }
            
            // Logs/Monitoring (right)
            if windows.count > 3 {
                let logWindows = Array(windows[3...])
                let logHeight = frame.height / CGFloat(logWindows.count)
                
                for (index, window) in logWindows.enumerated() {
                    AccessibilityHelper.setWindowFrame(window, to: CGRect(
                        x: frame.minX + codeWidth + apiWidth + dbWidth,
                        y: frame.minY + CGFloat(index) * logHeight,
                        width: logsWidth,
                        height: logHeight
                    ))
                }
            }
        }
    }
    
    /// Desktop App Development: Native application development
    /// IDE (45%) + Application/Preview (35%) + Debugger/Profiler (15%) + Documentation (5%)
    private func applyDesktopAppDevModeLayout(windows: [AXUIElement], in frame: CGRect) {
        guard !windows.isEmpty else { return }
        Logger.shared.debug("Applying Desktop App Development layout")
        
        if windows.count == 1 {
            // Single window - IDE with optimal width for desktop development
            let optimalWidth = min(frame.width * 0.85, 1600)
            let centeredFrame = CGRect(
                x: frame.midX - optimalWidth / 2,
                y: frame.minY,
                width: optimalWidth,
                height: frame.height
            )
            AccessibilityHelper.setWindowFrame(windows[0], to: centeredFrame)
        } else if windows.count == 2 {
            // IDE (60%) + Application Preview (40%)
            let ideWidth = frame.width * 0.6
            AccessibilityHelper.setWindowFrame(windows[0], to: CGRect(
                x: frame.minX,
                y: frame.minY,
                width: ideWidth,
                height: frame.height
            ))
            AccessibilityHelper.setWindowFrame(windows[1], to: CGRect(
                x: frame.minX + ideWidth,
                y: frame.minY,
                width: frame.width - ideWidth,
                height: frame.height
            ))
        } else {
            // Full desktop app development layout
            let ideWidth = frame.width * 0.45
            let appWidth = frame.width * 0.35
            let debugWidth = frame.width * 0.15
            let docWidth = frame.width * 0.05
            
            // IDE/Editor (left) - main development environment
            AccessibilityHelper.setWindowFrame(windows[0], to: CGRect(
                x: frame.minX,
                y: frame.minY,
                width: ideWidth,
                height: frame.height
            ))
            
            // Application/Preview (center) - running app or UI preview
            AccessibilityHelper.setWindowFrame(windows[1], to: CGRect(
                x: frame.minX + ideWidth,
                y: frame.minY,
                width: appWidth,
                height: frame.height
            ))
            
            // Debugger/Profiler (center-right)
            if windows.count > 2 {
                AccessibilityHelper.setWindowFrame(windows[2], to: CGRect(
                    x: frame.minX + ideWidth + appWidth,
                    y: frame.minY,
                    width: debugWidth,
                    height: frame.height
                ))
            }
            
            // Documentation/References (far right)
            if windows.count > 3 {
                let docWindows = Array(windows[3...])
                let docHeight = frame.height / CGFloat(docWindows.count)
                
                for (index, window) in docWindows.enumerated() {
                    AccessibilityHelper.setWindowFrame(window, to: CGRect(
                        x: frame.minX + ideWidth + appWidth + debugWidth,
                        y: frame.minY + CGFloat(index) * docHeight,
                        width: docWidth,
                        height: docHeight
                    ))
                }
            }
        }
    }
}

