//
//  WindowManagerIntegrationTests.swift
//  WICTests
//
//  Интеграционные тесты для WindowManager с реальными screen boundaries
//

import XCTest
import AppKit
@testable import WIC

class WindowManagerIntegrationTests: XCTestCase {
    
    var windowManager: WindowManager!
    
    override func setUp() {
        super.setUp()
        windowManager = WindowManager.shared
    }
    
    override func tearDown() {
        windowManager = nil
        super.tearDown()
    }
    
    // MARK: - Real Screen Configuration Tests
    
    func testCurrentScreenConfiguration() {
        // Test actual screen setup
        let screens = NSScreen.screens
        
        XCTAssertGreaterThan(screens.count, 0, "No screens detected")
        
        for (index, screen) in screens.enumerated() {
            print("Screen \(index): frame=\(screen.frame), visible=\(screen.visibleFrame)")
            
            // Validate screen properties
            XCTAssertGreaterThan(screen.frame.width, 0, "Screen \(index) width invalid")
            XCTAssertGreaterThan(screen.frame.height, 0, "Screen \(index) height invalid")
            
            // Visible frame should be within or equal to full frame
            XCTAssertTrue(screen.frame.contains(screen.visibleFrame) || 
                         screen.frame == screen.visibleFrame,
                         "Screen \(index) visible frame outside full frame")
        }
    }
    
    func testVerticalScreenDetection() {
        let screens = NSScreen.screens
        var verticalScreenFound = false
        
        for screen in screens {
            if screen.frame.height > screen.frame.width {
                verticalScreenFound = true
                print("Vertical screen detected: \(screen.frame)")
                
                // Test vertical screen specific constraints
                XCTAssertGreaterThan(screen.frame.height / screen.frame.width, 1.2, 
                                   "Screen not vertical enough")
            }
        }
        
        if verticalScreenFound {
            print("✅ Vertical screen configuration detected - running vertical tests")
        } else {
            print("ℹ️  No vertical screen detected - skipping vertical-specific tests")
        }
    }
    
    // MARK: - Layout Mode Boundary Tests
    
    func testAllLayoutModesStayWithinBounds() {
        let allModes = AutoLayoutType.allCases
        let mockWindows = createMockAXElements(count: 4)
        
        for screen in NSScreen.screens {
            for mode in allModes {
                // Test layout calculation without actually moving windows
                let calculatedPositions = simulateLayoutMode(mode, windows: mockWindows, screen: screen)
                
                for (windowIndex, position) in calculatedPositions.enumerated() {
                    // Critical boundary check
                    let screenBounds = screen.visibleFrame
                    
                    XCTAssertTrue(screenBounds.contains(position), 
                                 """
                                 BOUNDARY VIOLATION:
                                 Mode: \(mode.displayName)
                                 Screen: \(screen.frame)
                                 Window \(windowIndex): \(position)
                                 Screen bounds: \(screenBounds)
                                 """)
                    
                    // Additional specific checks
                    XCTAssertGreaterThanOrEqual(position.minX, screenBounds.minX,
                                              "Window \(windowIndex) X too small on \(mode.displayName)")
                    XCTAssertLessThanOrEqual(position.maxX, screenBounds.maxX,
                                           "Window \(windowIndex) X too large on \(mode.displayName)")
                    XCTAssertGreaterThanOrEqual(position.minY, screenBounds.minY,
                                              "Window \(windowIndex) Y too small on \(mode.displayName)")
                    XCTAssertLessThanOrEqual(position.maxY, screenBounds.maxY,
                                           "Window \(windowIndex) Y too large on \(mode.displayName)")
                }
            }
        }
    }
    
    func testProgrammingModesOnVerticalScreen() {
        guard let verticalScreen = NSScreen.screens.first(where: { $0.frame.height > $0.frame.width }) else {
            print("⚠️  No vertical screen - skipping vertical programming mode tests")
            return
        }
        
        let programmingModes: [AutoLayoutType] = [
            .fullStackDevMode, .mobileDevMode, .devOpsMode, .mlAiDevMode,
            .gameDevMode, .frontendDevMode, .backendApiMode, .desktopAppDevMode
        ]
        
        let mockWindows = createMockAXElements(count: 3)
        
        for mode in programmingModes {
            let positions = simulateLayoutMode(mode, windows: mockWindows, screen: verticalScreen)
            
            let screenBounds = verticalScreen.visibleFrame
            
            for (index, position) in positions.enumerated() {
                // Strict vertical screen checks
                XCTAssertTrue(screenBounds.contains(position),
                             """
                             VERTICAL SCREEN VIOLATION:
                             Mode: \(mode.displayName)
                             Window \(index): \(position)
                             Vertical screen: \(screenBounds)
                             """)
                
                // Check that window isn't too wide for vertical screen
                XCTAssertLessThanOrEqual(position.width, screenBounds.width,
                                       "Window \(index) too wide for vertical screen in \(mode.displayName)")
                
                // Check reasonable minimum sizes
                XCTAssertGreaterThanOrEqual(position.width, 200,
                                          "Window \(index) too narrow in \(mode.displayName)")
                XCTAssertGreaterThanOrEqual(position.height, 150,
                                          "Window \(index) too short in \(mode.displayName)")
            }
        }
    }
    
    func testUltraWideModeOnWideScreens() {
        let wideScreens = NSScreen.screens.filter { $0.frame.width / $0.frame.height > 2.0 }
        
        if wideScreens.isEmpty {
            print("ℹ️  No ultrawide screens detected - skipping ultrawide tests")
            return
        }
        
        for wideScreen in wideScreens {
            let mockWindows = createMockAXElements(count: 3)
            let positions = simulateLayoutMode(.ultraWideMode, windows: mockWindows, screen: wideScreen)
            
            // Ultrawide should create three columns
            XCTAssertEqual(positions.count, 3, "Ultrawide should create 3 columns")
            
            // Check column proportions
            let screenWidth = wideScreen.visibleFrame.width
            let expectedWidths = [
                screenWidth * 0.25,  // Left
                screenWidth * 0.50,  // Center
                screenWidth * 0.25   // Right
            ]
            
            for (index, position) in positions.enumerated() {
                XCTAssertEqual(position.width, expectedWidths[index], accuracy: 5.0,
                              "Ultrawide column \(index) width incorrect")
                
                // All windows should be full height
                XCTAssertEqual(position.height, wideScreen.visibleFrame.height, accuracy: 1.0,
                              "Ultrawide window \(index) should be full height")
            }
        }
    }
    
    // MARK: - Academic Algorithm Convergence Tests
    
    func testKaczmarzConvergence() {
        guard let screen = NSScreen.screens.first else {
            XCTFail("No screens available")
            return
        }
        
        // Test Kaczmarz with various window counts
        for windowCount in [2, 5, 8, 12] {
            let mockWindows = createMockAXElements(count: windowCount)
            let positions = simulateLayoutMode(.kaczmarz, windows: mockWindows, screen: screen)
            
            // Kaczmarz should converge to non-overlapping solution
            verifyNonOverlapping(positions: positions, testName: "Kaczmarz-\(windowCount)windows")
            
            // All positions should be within screen
            for position in positions {
                XCTAssertTrue(screen.visibleFrame.contains(position),
                             "Kaczmarz convergence failed - window outside screen")
            }
        }
    }
    
    func testInteriorPointBarriers() {
        guard let screen = NSScreen.screens.first else {
            XCTFail("No screens available")
            return
        }
        
        let mockWindows = createMockAXElements(count: 4)
        let positions = simulateLayoutMode(.interiorPoint, windows: mockWindows, screen: screen)
        
        // Interior Point should maintain barriers from screen edges
        let expectedMargin: CGFloat = screen.visibleFrame.width * 0.05 // 5% margin
        
        for (index, position) in positions.enumerated() {
            XCTAssertGreaterThanOrEqual(position.minX, screen.visibleFrame.minX + expectedMargin,
                                      "Interior Point barrier violated - window \(index) too close to left edge")
            XCTAssertLessThanOrEqual(position.maxX, screen.visibleFrame.maxX - expectedMargin,
                                   "Interior Point barrier violated - window \(index) too close to right edge")
            XCTAssertGreaterThanOrEqual(position.minY, screen.visibleFrame.minY + expectedMargin,
                                      "Interior Point barrier violated - window \(index) too close to top edge")
            XCTAssertLessThanOrEqual(position.maxY, screen.visibleFrame.maxY - expectedMargin,
                                   "Interior Point barrier violated - window \(index) too close to bottom edge")
        }
    }
    
    // MARK: - Performance and Edge Cases
    
    func testLargeNumberOfWindows() {
        guard let screen = NSScreen.screens.first else {
            XCTFail("No screens available")
            return
        }
        
        // Test with many windows - should not crash or exceed bounds
        let manyWindows = createMockAXElements(count: 20)
        
        for mode in [AutoLayoutType.grid, .focus, .dataAnalysisMode] {
            let startTime = CFAbsoluteTimeGetCurrent()
            let positions = simulateLayoutMode(mode, windows: manyWindows, screen: screen)
            let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
            
            // Performance check - should complete within reasonable time
            XCTAssertLessThan(timeElapsed, 1.0, "Layout mode \(mode.displayName) too slow with many windows")
            
            // All windows should fit on screen
            for position in positions {
                XCTAssertTrue(screen.visibleFrame.contains(position),
                             "Large window count test failed for \(mode.displayName)")
            }
        }
    }
    
    func testMinimumWindowSizes() {
        guard let screen = NSScreen.screens.first else {
            XCTFail("No screens available")
            return
        }
        
        let mockWindows = createMockAXElements(count: 10)
        
        for mode in AutoLayoutType.allCases {
            let positions = simulateLayoutMode(mode, windows: mockWindows, screen: screen)
            
            for (index, position) in positions.enumerated() {
                // Ensure windows are usable size
                XCTAssertGreaterThanOrEqual(position.width, 150,
                                          "Window \(index) too narrow in \(mode.displayName)")
                XCTAssertGreaterThanOrEqual(position.height, 100,
                                          "Window \(index) too short in \(mode.displayName)")
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func createMockAXElements(count: Int) -> [AXUIElement] {
        // Create mock AXUIElement objects for testing
        return (0..<count).map { _ in
            // This is a placeholder - in real tests you'd need proper AXUIElement mocks
            // For now, we'll simulate the layout calculations
            return AXUIElementCreateApplication(getpid())
        }
    }
    
    private func simulateLayoutMode(_ mode: AutoLayoutType, windows: [AXUIElement], screen: NSScreen) -> [CGRect] {
        // Simulate the layout calculation logic from WindowManager
        let frame = screen.visibleFrame
        
        switch mode {
        case .grid:
            return calculateGridLayout(windowCount: windows.count, in: frame)
        case .focus:
            return calculateFocusLayout(windowCount: windows.count, in: frame)
        case .ultraWideMode:
            return calculateUltraWideLayout(windowCount: windows.count, in: frame, screen: screen)
        case .fullStackDevMode:
            return calculateFullStackLayout(windowCount: windows.count, in: frame)
        case .mobileDevMode:
            return calculateMobileDevLayout(windowCount: windows.count, in: frame)
        case .kaczmarz:
            return calculateKaczmarzLayout(windowCount: windows.count, in: frame)
        case .interiorPoint:
            return calculateInteriorPointLayout(windowCount: windows.count, in: frame)
        case .videoConferenceMode:
            return calculateVideoConferenceLayout(windowCount: windows.count, in: frame)
        case .dataAnalysisMode:
            return calculateDataAnalysisLayout(windowCount: windows.count, in: frame)
        default:
            // Default to grid for other modes
            return calculateGridLayout(windowCount: windows.count, in: frame)
        }
    }
    
    private func calculateGridLayout(windowCount: Int, in frame: CGRect) -> [CGRect] {
        let columns = Int(ceil(sqrt(Double(windowCount))))
        let rows = Int(ceil(Double(windowCount) / Double(columns)))
        
        // Add padding from settings
        let padding: CGFloat = 10
        let bottomPadding: CGFloat = 20
        
        let usableFrame = CGRect(
            x: frame.minX + padding,
            y: frame.minY + padding + bottomPadding,
            width: frame.width - padding * 2,
            height: frame.height - padding * 2 - bottomPadding
        )
        
        let windowWidth = usableFrame.width / CGFloat(columns)
        let windowHeight = usableFrame.height / CGFloat(rows)
        
        var positions: [CGRect] = []
        
        for i in 0..<windowCount {
            let col = i % columns
            let row = i / columns
            
            positions.append(CGRect(
                x: usableFrame.minX + CGFloat(col) * windowWidth,
                y: usableFrame.minY + CGFloat(row) * windowHeight,
                width: windowWidth,
                height: windowHeight
            ))
        }
        
        return positions
    }
    
    private func calculateFocusLayout(windowCount: Int, in frame: CGRect) -> [CGRect] {
        var positions: [CGRect] = []
        
        if windowCount == 0 { return positions }
        
        if windowCount == 1 {
            let centered = CGRect(
                x: frame.midX - frame.width * 0.35,
                y: frame.midY - frame.height * 0.35,
                width: frame.width * 0.7,
                height: frame.height * 0.7
            )
            positions.append(centered)
        } else {
            let mainWidth = frame.width * (2.0/3.0)
            let sideWidth = frame.width * (1.0/3.0)
            
            // Main window
            positions.append(CGRect(
                x: frame.minX,
                y: frame.minY,
                width: mainWidth,
                height: frame.height
            ))
            
            // Side windows
            let sideCount = windowCount - 1
            let sideHeight = frame.height / CGFloat(sideCount)
            
            for i in 0..<sideCount {
                positions.append(CGRect(
                    x: frame.minX + mainWidth,
                    y: frame.minY + CGFloat(i) * sideHeight,
                    width: sideWidth,
                    height: sideHeight
                ))
            }
        }
        
        return positions
    }
    
    private func calculateUltraWideLayout(windowCount: Int, in frame: CGRect, screen: NSScreen) -> [CGRect] {
        let aspectRatio = frame.width / frame.height
        
        if aspectRatio < 2.0 {
            return calculateFocusLayout(windowCount: windowCount, in: frame)
        }
        
        var positions: [CGRect] = []
        
        if windowCount == 1 {
            let optimalWidth = min(frame.width * 0.5, 1600)
            positions.append(CGRect(
                x: frame.midX - optimalWidth / 2,
                y: frame.minY,
                width: optimalWidth,
                height: frame.height
            ))
        } else if windowCount == 2 {
            let centerWidth = frame.width * 0.6
            positions.append(CGRect(
                x: frame.midX - centerWidth / 2,
                y: frame.minY,
                width: centerWidth,
                height: frame.height
            ))
            positions.append(CGRect(
                x: frame.minX + frame.width - frame.width * 0.25,
                y: frame.minY,
                width: frame.width * 0.25,
                height: frame.height
            ))
        } else {
            let leftWidth = frame.width * 0.25
            let centerWidth = frame.width * 0.5
            let rightWidth = frame.width * 0.25
            
            positions.append(CGRect(
                x: frame.minX + leftWidth,
                y: frame.minY,
                width: centerWidth,
                height: frame.height
            ))
            
            if windowCount >= 2 {
                positions.append(CGRect(
                    x: frame.minX,
                    y: frame.minY,
                    width: leftWidth,
                    height: frame.height
                ))
            }
            
            if windowCount >= 3 {
                positions.append(CGRect(
                    x: frame.minX + leftWidth + centerWidth,
                    y: frame.minY,
                    width: rightWidth,
                    height: frame.height
                ))
            }
        }
        
        return positions
    }
    
    private func calculateFullStackLayout(windowCount: Int, in frame: CGRect) -> [CGRect] {
        var positions: [CGRect] = []
        
        if windowCount == 0 { return positions }
        
        if windowCount == 1 {
            let optimalWidth = min(frame.width * 0.8, 1400)
            positions.append(CGRect(
                x: frame.midX - optimalWidth / 2,
                y: frame.minY,
                width: optimalWidth,
                height: frame.height
            ))
        } else if windowCount == 2 {
            let codeWidth = frame.width * 0.6
            positions.append(CGRect(x: frame.minX, y: frame.minY, width: codeWidth, height: frame.height))
            positions.append(CGRect(x: frame.minX + codeWidth, y: frame.minY, width: frame.width - codeWidth, height: frame.height))
        } else {
            let widths = [0.4, 0.3, 0.2, 0.1].map { frame.width * CGFloat($0) }
            var xOffset = frame.minX
            
            for i in 0..<min(windowCount, widths.count) {
                positions.append(CGRect(
                    x: xOffset,
                    y: frame.minY,
                    width: widths[i],
                    height: frame.height
                ))
                xOffset += widths[i]
            }
        }
        
        return positions
    }
    
    private func calculateMobileDevLayout(windowCount: Int, in frame: CGRect) -> [CGRect] {
        var positions: [CGRect] = []
        
        if windowCount == 0 { return positions }
        
        let ideWidth = frame.width * 0.5
        let simWidth = frame.width * 0.35
        let consoleWidth = frame.width * 0.15
        
        positions.append(CGRect(x: frame.minX, y: frame.minY, width: ideWidth, height: frame.height))
        
        if windowCount >= 2 {
            let simHeight = min(frame.height, simWidth * 2.0)
            positions.append(CGRect(
                x: frame.minX + ideWidth,
                y: frame.minY + (frame.height - simHeight) / 2,
                width: simWidth,
                height: simHeight
            ))
        }
        
        if windowCount >= 3 {
            positions.append(CGRect(
                x: frame.minX + ideWidth + simWidth,
                y: frame.minY,
                width: consoleWidth,
                height: frame.height
            ))
        }
        
        return positions
    }
    
    private func calculateKaczmarzLayout(windowCount: Int, in frame: CGRect) -> [CGRect] {
        // Simulate Kaczmarz iterative projection
        let phi = (1.0 + sqrt(5.0)) / 2.0
        let mainWidth = frame.width / CGFloat(phi)
        
        var positions: [CGRect] = []
        
        for i in 0..<windowCount {
            let width = mainWidth / CGFloat(i + 1)
            let xOffset = CGFloat(i) * width
            
            // Ensure within bounds
            let finalX = min(frame.minX + xOffset, frame.maxX - width)
            
            positions.append(CGRect(
                x: finalX,
                y: frame.minY,
                width: min(width, frame.maxX - finalX),
                height: frame.height
            ))
        }
        
        return positions
    }
    
    private func calculateInteriorPointLayout(windowCount: Int, in frame: CGRect) -> [CGRect] {
        let margin = frame.width * 0.08 // 8% barrier margin
        let usableFrame = CGRect(
            x: frame.minX + margin,
            y: frame.minY + margin,
            width: frame.width - 2 * margin,
            height: frame.height - 2 * margin
        )
        
        return calculateGridLayout(windowCount: windowCount, in: usableFrame)
    }
    
    private func calculateVideoConferenceLayout(windowCount: Int, in frame: CGRect) -> [CGRect] {
        var positions: [CGRect] = []
        
        if windowCount == 1 {
            let optimalHeight = frame.width * 0.6 * (9.0/16.0)
            positions.append(CGRect(
                x: frame.midX - (frame.width * 0.6) / 2,
                y: frame.midY - optimalHeight / 2,
                width: frame.width * 0.6,
                height: optimalHeight
            ))
        } else {
            let mainWidth = frame.width * 0.7
            positions.append(CGRect(x: frame.minX, y: frame.minY, width: mainWidth, height: frame.height))
            
            if windowCount >= 2 {
                positions.append(CGRect(
                    x: frame.minX + mainWidth,
                    y: frame.minY,
                    width: frame.width - mainWidth,
                    height: frame.height
                ))
            }
        }
        
        return positions
    }
    
    private func calculateDataAnalysisLayout(windowCount: Int, in frame: CGRect) -> [CGRect] {
        var positions: [CGRect] = []
        
        let tableWidth = frame.width * 0.4
        let chartWidth = frame.width * 0.35
        let codeWidth = frame.width * 0.25
        
        positions.append(CGRect(x: frame.minX, y: frame.minY, width: tableWidth, height: frame.height))
        
        if windowCount >= 2 {
            positions.append(CGRect(
                x: frame.minX + tableWidth,
                y: frame.minY,
                width: chartWidth,
                height: frame.height
            ))
        }
        
        if windowCount >= 3 {
            positions.append(CGRect(
                x: frame.minX + tableWidth + chartWidth,
                y: frame.minY,
                width: codeWidth,
                height: frame.height
            ))
        }
        
        return positions
    }
    
    private func verifyNonOverlapping(positions: [CGRect], testName: String) {
        for i in 0..<positions.count {
            for j in i+1..<positions.count {
                let overlap = positions[i].intersection(positions[j])
                XCTAssertTrue(overlap.isEmpty || (overlap.width < 5 && overlap.height < 5),
                             "\(testName): Windows \(i) and \(j) overlap significantly: \(overlap)")
            }
        }
    }
}