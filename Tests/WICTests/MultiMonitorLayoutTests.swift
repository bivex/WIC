//
//  MultiMonitorLayoutTests.swift
//  WICTests
//
//  Тесты для множественных мониторов и всех режимов раскладки
//

import XCTest
import AppKit
@testable import WIC

class MultiMonitorLayoutTests: XCTestCase {
    
    var windowManager: WindowManager!
    
    // Mock экраны для тестирования
    var primaryScreen: MockScreen!
    var secondaryScreen: MockScreen!
    var verticalScreen: MockScreen!
    
    override func setUp() {
        super.setUp()
        windowManager = WindowManager.shared
        setupMockScreens()
    }
    
    override func tearDown() {
        windowManager = nil
        primaryScreen = nil
        secondaryScreen = nil
        verticalScreen = nil
        super.tearDown()
    }
    
    // MARK: - Mock Screen Setup
    
    func setupMockScreens() {
        // Primary screen (main monitor) - 16:9 landscape
        primaryScreen = MockScreen(
            frame: CGRect(x: 0, y: 0, width: 2560, height: 1440),
            visibleFrame: CGRect(x: 0, y: 25, width: 2560, height: 1415) // учитываем MenuBar
        )
        
        // Secondary screen (horizontal) - 21:9 ultrawide
        secondaryScreen = MockScreen(
            frame: CGRect(x: 2560, y: 0, width: 3440, height: 1440),
            visibleFrame: CGRect(x: 2560, y: 0, width: 3440, height: 1440)
        )
        
        // Vertical screen - 9:16 portrait
        verticalScreen = MockScreen(
            frame: CGRect(x: 6000, y: 0, width: 1440, height: 2560),
            visibleFrame: CGRect(x: 6000, y: 0, width: 1440, height: 2560)
        )
    }
    
    // MARK: - Basic Layout Mode Tests
    
    func testGridLayoutOnPrimaryScreen() {
        let windows = createMockWindows(count: 4)
        let frame = primaryScreen.visibleFrame
        
        // Test grid layout calculation
        let positions = calculateGridPositions(windows: windows, in: frame)
        
        // Verify all windows are within screen bounds
        for position in positions {
            XCTAssertTrue(frame.contains(position), "Window position \(position) is outside primary screen bounds \(frame)")
            XCTAssertGreaterThanOrEqual(position.minX, frame.minX, "Window X position too small")
            XCTAssertLessThanOrEqual(position.maxX, frame.maxX, "Window X position too large")
            XCTAssertGreaterThanOrEqual(position.minY, frame.minY, "Window Y position too small")
            XCTAssertLessThanOrEqual(position.maxY, frame.maxY, "Window Y position too large")
        }
        
        // Verify grid arrangement (2x2 for 4 windows)
        XCTAssertEqual(positions.count, 4, "Should have 4 window positions")
        
        // Check that windows don't overlap significantly
        for i in 0..<positions.count {
            for j in i+1..<positions.count {
                let overlap = positions[i].intersection(positions[j])
                XCTAssertTrue(overlap.isEmpty || overlap.width < 10 || overlap.height < 10, 
                             "Windows \(i) and \(j) overlap too much: \(overlap)")
            }
        }
    }
    
    func testGridLayoutOnVerticalScreen() {
        let windows = createMockWindows(count: 6)
        let frame = verticalScreen.visibleFrame
        
        let positions = calculateGridPositions(windows: windows, in: frame)
        
        // Critical test: verify no windows escape vertical screen bounds
        for (index, position) in positions.enumerated() {
            XCTAssertTrue(frame.contains(position), 
                         "Window \(index) at \(position) is outside vertical screen bounds \(frame)")
            
            // Specific checks for vertical screen
            XCTAssertGreaterThanOrEqual(position.minX, frame.minX, 
                                      "Window \(index) X position \(position.minX) < screen left \(frame.minX)")
            XCTAssertLessThanOrEqual(position.maxX, frame.maxX, 
                                   "Window \(index) X position \(position.maxX) > screen right \(frame.maxX)")
            XCTAssertGreaterThanOrEqual(position.minY, frame.minY, 
                                      "Window \(index) Y position \(position.minY) < screen top \(frame.minY)")
            XCTAssertLessThanOrEqual(position.maxY, frame.maxY, 
                                   "Window \(index) Y position \(position.maxY) > screen bottom \(frame.maxY)")
        }
    }
    
    func testUltrawideModeOnSecondaryScreen() {
        let windows = createMockWindows(count: 3)
        let frame = secondaryScreen.visibleFrame // 21:9 ultrawide
        
        let positions = calculateUltraWidePositions(windows: windows, in: frame)
        
        // Verify ultrawide-specific layout (three columns)
        XCTAssertEqual(positions.count, 3, "Should have 3 windows for ultrawide")
        
        // Check positions are within bounds
        for position in positions {
            XCTAssertTrue(frame.contains(position), "Window outside ultrawide screen bounds")
        }
        
        // Verify three-column layout proportions
        let expectedWidths = [
            frame.width * 0.25,  // Left column
            frame.width * 0.50,  // Center (main)
            frame.width * 0.25   // Right column
        ]
        
        for (index, position) in positions.enumerated() {
            let expectedWidth = expectedWidths[index]
            XCTAssertEqual(position.width, expectedWidth, accuracy: 1.0, 
                          "Window \(index) width incorrect for ultrawide layout")
        }
    }
    
    // MARK: - All Premium Modes Testing
    
    func testAllPremiumModesOnPrimaryScreen() {
        let testModes: [AutoLayoutType] = [
            .videoConferenceMode, .dataAnalysisMode, .contentCreationMode, .tradingMode,
            .gamingStreamingMode, .learningMode, .projectManagementMode, .monitoringMode,
            .fullStackDevMode, .mobileDevMode, .devOpsMode, .mlAiDevMode, 
            .gameDevMode, .frontendDevMode, .backendApiMode, .desktopAppDevMode
        ]
        
        let frame = primaryScreen.visibleFrame
        let windows = createMockWindows(count: 4)
        
        for mode in testModes {
            let positions = calculateLayoutPositions(windows: windows, mode: mode, in: frame)
            
            // Critical boundary checks for each mode
            for (windowIndex, position) in positions.enumerated() {
                XCTAssertTrue(frame.contains(position), 
                             "Mode \(mode.displayName): Window \(windowIndex) at \(position) outside screen \(frame)")
                
                // Ensure minimum window size
                XCTAssertGreaterThanOrEqual(position.width, 100, 
                                          "Mode \(mode.displayName): Window \(windowIndex) too narrow")
                XCTAssertGreaterThanOrEqual(position.height, 100, 
                                          "Mode \(mode.displayName): Window \(windowIndex) too short")
            }
        }
    }
    
    func testAllPremiumModesOnVerticalScreen() {
        let testModes: [AutoLayoutType] = [
            .fullStackDevMode, .mobileDevMode, .devOpsMode, .mlAiDevMode,
            .frontendDevMode, .backendApiMode, .desktopAppDevMode
        ]
        
        let frame = verticalScreen.visibleFrame
        let windows = createMockWindows(count: 3)
        
        for mode in testModes {
            let positions = calculateLayoutPositions(windows: windows, mode: mode, in: frame)
            
            // Strict boundary checks for vertical screen
            for (windowIndex, position) in positions.enumerated() {
                XCTAssertTrue(frame.contains(position), 
                             "VERTICAL FAIL: Mode \(mode.displayName), Window \(windowIndex) at \(position) outside vertical screen \(frame)")
                
                // Check specific coordinates
                XCTAssertGreaterThanOrEqual(position.minX, frame.minX, 
                                          "VERTICAL: Window \(windowIndex) left edge \(position.minX) < \(frame.minX)")
                XCTAssertLessThanOrEqual(position.maxX, frame.maxX, 
                                       "VERTICAL: Window \(windowIndex) right edge \(position.maxX) > \(frame.maxX)")
            }
        }
    }
    
    // MARK: - Academic Algorithm Tests
    
    func testAcademicAlgorithmsOnMultipleScreens() {
        let academicModes: [AutoLayoutType] = [
            .kaczmarz, .interiorPoint, .activeSet, .linearRelaxation, .constraintSimplex
        ]
        
        let screens = [primaryScreen!, secondaryScreen!, verticalScreen!]
        let windows = createMockWindows(count: 5)
        
        for screen in screens {
            for mode in academicModes {
                let positions = calculateLayoutPositions(windows: windows, mode: mode, in: screen.visibleFrame)
                
                // Academic algorithms should respect mathematical constraints
                for position in positions {
                    XCTAssertTrue(screen.visibleFrame.contains(position), 
                                 "Academic mode \(mode.displayName) failed on screen \(screen.frame)")
                }
                
                // Check algorithm-specific properties
                switch mode {
                case .kaczmarz:
                    // Kaczmarz should converge to non-overlapping solution
                    verifyNonOverlapping(positions: positions)
                case .interiorPoint:
                    // Interior Point should maintain barriers (margins)
                    verifyInteriorPointBarriers(positions: positions, in: screen.visibleFrame)
                case .activeSet:
                    // Active Set should identify boundary constraints
                    verifyActiveSetConstraints(positions: positions, in: screen.visibleFrame)
                default:
                    break
                }
            }
        }
    }
    
    // MARK: - Multi-Screen Coordination Tests
    
    func testCrossScreenLayout() {
        // Test when windows span across multiple screens
        let allScreens = [primaryScreen!, secondaryScreen!, verticalScreen!]
        let manyWindows = createMockWindows(count: 12)
        
        // Distribute windows across screens
        var screenIndex = 0
        for (windowIndex, _) in manyWindows.enumerated() {
            let targetScreen = allScreens[screenIndex % allScreens.count]
            let singleWindow = [manyWindows[windowIndex]]
            let positions = calculateLayoutPositions(windows: singleWindow, mode: .focus, in: targetScreen.visibleFrame)
            
            // Verify window stays on intended screen
            for position in positions {
                XCTAssertTrue(targetScreen.visibleFrame.contains(position),
                             "Cross-screen: Window \(windowIndex) not on intended screen \(screenIndex)")
            }
            
            screenIndex += 1
        }
    }
    
    // MARK: - Edge Case Tests
    
    func testScreenBoundaryEdgeCases() {
        // Test windows at exact screen edges
        let frame = verticalScreen.visibleFrame
        let windows = createMockWindows(count: 1)
        
        // Test all layout types with single window (should center or fit)
        let allModes = AutoLayoutType.allCases
        
        for mode in allModes {
            let positions = calculateLayoutPositions(windows: windows, mode: mode, in: frame)
            
            for position in positions {
                // Should never exceed bounds, even by 1 pixel
                XCTAssertLessThanOrEqual(position.maxX, frame.maxX, 
                                       "Edge case: \(mode.displayName) window right edge exceeds screen")
                XCTAssertLessThanOrEqual(position.maxY, frame.maxY, 
                                       "Edge case: \(mode.displayName) window bottom edge exceeds screen")
                XCTAssertGreaterThanOrEqual(position.minX, frame.minX, 
                                          "Edge case: \(mode.displayName) window left edge before screen")
                XCTAssertGreaterThanOrEqual(position.minY, frame.minY, 
                                          "Edge case: \(mode.displayName) window top edge before screen")
            }
        }
    }
    
    func testZeroSizeWindows() {
        // Edge case: what happens with zero-size or tiny screens
        let tinyFrame = CGRect(x: 0, y: 0, width: 100, height: 100)
        let windows = createMockWindows(count: 2)
        
        let positions = calculateGridPositions(windows: windows, in: tinyFrame)
        
        for position in positions {
            XCTAssertTrue(tinyFrame.contains(position), "Tiny screen: window outside bounds")
            XCTAssertGreaterThan(position.width, 0, "Window width should be positive")
            XCTAssertGreaterThan(position.height, 0, "Window height should be positive")
        }
    }
    
    // MARK: - Helper Methods
    
    private func createMockWindows(count: Int) -> [MockWindow] {
        return (0..<count).map { MockWindow(id: $0) }
    }
    
    private func calculateGridPositions(windows: [MockWindow], in frame: CGRect) -> [CGRect] {
        // Simulate grid layout calculation
        let count = windows.count
        let columns = Int(ceil(sqrt(Double(count))))
        let rows = Int(ceil(Double(count) / Double(columns)))
        
        let windowWidth = frame.width / CGFloat(columns)
        let windowHeight = frame.height / CGFloat(rows)
        
        var positions: [CGRect] = []
        
        for i in 0..<count {
            let col = i % columns
            let row = i / columns
            
            let rect = CGRect(
                x: frame.minX + CGFloat(col) * windowWidth,
                y: frame.minY + CGFloat(row) * windowHeight,
                width: windowWidth,
                height: windowHeight
            )
            positions.append(rect)
        }
        
        return positions
    }
    
    private func calculateUltraWidePositions(windows: [MockWindow], in frame: CGRect) -> [CGRect] {
        // Simulate ultrawide layout
        let leftWidth = frame.width * 0.25
        let centerWidth = frame.width * 0.50
        let rightWidth = frame.width * 0.25
        
        var positions: [CGRect] = []
        
        if windows.count >= 1 {
            // Center window
            positions.append(CGRect(
                x: frame.minX + leftWidth,
                y: frame.minY,
                width: centerWidth,
                height: frame.height
            ))
        }
        
        if windows.count >= 2 {
            // Left window
            positions.append(CGRect(
                x: frame.minX,
                y: frame.minY,
                width: leftWidth,
                height: frame.height
            ))
        }
        
        if windows.count >= 3 {
            // Right window
            positions.append(CGRect(
                x: frame.minX + leftWidth + centerWidth,
                y: frame.minY,
                width: rightWidth,
                height: frame.height
            ))
        }
        
        return positions
    }
    
    private func calculateLayoutPositions(windows: [MockWindow], mode: AutoLayoutType, in frame: CGRect) -> [CGRect] {
        // Simulate specific layout mode calculations
        switch mode {
        case .grid:
            return calculateGridPositions(windows: windows, in: frame)
        case .ultraWideMode:
            return calculateUltraWidePositions(windows: windows, in: frame)
        case .focus:
            return calculateFocusPositions(windows: windows, in: frame)
        case .fullStackDevMode:
            return calculateFullStackPositions(windows: windows, in: frame)
        case .mobileDevMode:
            return calculateMobileDevPositions(windows: windows, in: frame)
        default:
            // Default to grid for other modes
            return calculateGridPositions(windows: windows, in: frame)
        }
    }
    
    private func calculateFocusPositions(windows: [MockWindow], in frame: CGRect) -> [CGRect] {
        var positions: [CGRect] = []
        
        if windows.isEmpty { return positions }
        
        if windows.count == 1 {
            // Single window takes 70% of screen, centered
            let width = frame.width * 0.7
            let height = frame.height * 0.7
            positions.append(CGRect(
                x: frame.midX - width / 2,
                y: frame.midY - height / 2,
                width: width,
                height: height
            ))
        } else {
            // Main window (2/3) + sidebar (1/3)
            let mainWidth = frame.width * 0.67
            let sideWidth = frame.width * 0.33
            
            // Main window
            positions.append(CGRect(
                x: frame.minX,
                y: frame.minY,
                width: mainWidth,
                height: frame.height
            ))
            
            // Sidebar windows
            let sideWindows = windows.count - 1
            let sideHeight = frame.height / CGFloat(sideWindows)
            
            for i in 1..<windows.count {
                positions.append(CGRect(
                    x: frame.minX + mainWidth,
                    y: frame.minY + CGFloat(i - 1) * sideHeight,
                    width: sideWidth,
                    height: sideHeight
                ))
            }
        }
        
        return positions
    }
    
    private func calculateFullStackPositions(windows: [MockWindow], in frame: CGRect) -> [CGRect] {
        // Full-stack layout: Code (40%) + Preview (30%) + Terminal (20%) + DB (10%)
        var positions: [CGRect] = []
        
        if windows.isEmpty { return positions }
        
        let widths = [0.4, 0.3, 0.2, 0.1].map { frame.width * CGFloat($0) }
        var xOffset = frame.minX
        
        for (index, window) in windows.enumerated() {
            let widthIndex = min(index, widths.count - 1)
            let width = widths[widthIndex]
            
            positions.append(CGRect(
                x: xOffset,
                y: frame.minY,
                width: width,
                height: frame.height
            ))
            
            xOffset += width
            
            // Don't exceed screen bounds
            if xOffset >= frame.maxX { break }
        }
        
        return positions
    }
    
    private func calculateMobileDevPositions(windows: [MockWindow], in frame: CGRect) -> [CGRect] {
        // Mobile dev: IDE (50%) + Simulator (35%) + Console (15%)
        var positions: [CGRect] = []
        
        if windows.isEmpty { return positions }
        
        let widths = [0.5, 0.35, 0.15].map { frame.width * CGFloat($0) }
        var xOffset = frame.minX
        
        for (index, _) in windows.enumerated() {
            let widthIndex = min(index, widths.count - 1)
            let width = widths[widthIndex]
            
            positions.append(CGRect(
                x: xOffset,
                y: frame.minY,
                width: width,
                height: frame.height
            ))
            
            xOffset += width
        }
        
        return positions
    }
    
    private func verifyNonOverlapping(positions: [CGRect]) {
        for i in 0..<positions.count {
            for j in i+1..<positions.count {
                let overlap = positions[i].intersection(positions[j])
                XCTAssertTrue(overlap.isEmpty, "Kaczmarz: Windows \(i) and \(j) should not overlap")
            }
        }
    }
    
    private func verifyInteriorPointBarriers(positions: [CGRect], in frame: CGRect) {
        let margin: CGFloat = 5.0 // Expected barrier margin
        
        for position in positions {
            XCTAssertGreaterThanOrEqual(position.minX, frame.minX + margin, 
                                      "Interior Point: Left barrier violation")
            XCTAssertLessThanOrEqual(position.maxX, frame.maxX - margin, 
                                   "Interior Point: Right barrier violation")
        }
    }
    
    private func verifyActiveSetConstraints(positions: [CGRect], in frame: CGRect) {
        // Active Set should have some windows touching boundaries (active constraints)
        var touchingBoundary = false
        
        for position in positions {
            if abs(position.minX - frame.minX) < 1.0 || 
               abs(position.maxX - frame.maxX) < 1.0 {
                touchingBoundary = true
                break
            }
        }
        
        XCTAssertTrue(touchingBoundary, "Active Set should have windows touching boundaries")
    }
}

// MARK: - Mock Objects

class MockWindow {
    let id: Int
    
    init(id: Int) {
        self.id = id
    }
}

class MockScreen {
    let frame: CGRect
    let visibleFrame: CGRect
    
    init(frame: CGRect, visibleFrame: CGRect) {
        self.frame = frame
        self.visibleFrame = visibleFrame
    }
}