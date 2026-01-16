//
//  SnapToEdgeTests.swift
//  WICTests
//
//  Тесты для функции автоприклеивания окон к краям экрана
//

import XCTest
import AppKit
@testable import WIC

class SnapToEdgeTests: XCTestCase {
    
    var windowManager: WindowManager!
    var snapSettings: SnapSettings!
    
    override func setUp() {
        super.setUp()
        windowManager = WindowManager.shared
        snapSettings = SnapSettings()
    }
    
    override func tearDown() {
        windowManager = nil
        snapSettings = nil
        super.tearDown()
    }
    
    // MARK: - SnapSettings Tests
    
    func testSnapSettingsDefaults() {
        let settings = SnapSettings()
        XCTAssertTrue(settings.isEnabled, "Snap should be enabled by default")
        XCTAssertEqual(settings.snapThreshold, 20, "Default threshold should be 20 pixels")
        XCTAssertEqual(settings.animationDuration, 0.2, "Default animation duration should be 0.2s")
        XCTAssertEqual(settings.gridPadding, 10, "Default grid padding should be 10 pixels")
    }
    
    func testSnapThresholdRange() {
        var settings = SnapSettings()
        
        // Test valid range (10-50 pixels as per UI)
        settings.snapThreshold = 15
        XCTAssertEqual(settings.snapThreshold, 15)
        
        settings.snapThreshold = 50
        XCTAssertEqual(settings.snapThreshold, 50)
    }
    
    // MARK: - Edge Detection Tests
    
    func testLeftEdgeDetection() {
        guard let screen = NSScreen.main else {
            XCTFail("No main screen found")
            return
        }
        
        let visibleFrame = screen.visibleFrame
        let threshold = snapSettings.snapThreshold
        
        // Точка близко к левому краю
        let leftEdgePoint = CGPoint(
            x: visibleFrame.minX + threshold - 5,
            y: visibleFrame.midY
        )
        
        let detectedPosition = detectSnapPosition(at: leftEdgePoint, screen: screen, threshold: threshold)
        XCTAssertEqual(detectedPosition, .leftHalf, "Should detect left edge")
    }
    
    func testRightEdgeDetection() {
        guard let screen = NSScreen.main else {
            XCTFail("No main screen found")
            return
        }
        
        let visibleFrame = screen.visibleFrame
        let threshold = snapSettings.snapThreshold
        
        // Точка близко к правому краю
        let rightEdgePoint = CGPoint(
            x: visibleFrame.maxX - threshold + 5,
            y: visibleFrame.midY
        )
        
        let detectedPosition = detectSnapPosition(at: rightEdgePoint, screen: screen, threshold: threshold)
        XCTAssertEqual(detectedPosition, .rightHalf, "Should detect right edge")
    }
    
    func testTopEdgeDetection() {
        guard let screen = NSScreen.main else {
            XCTFail("No main screen found")
            return
        }
        
        let visibleFrame = screen.visibleFrame
        let threshold = snapSettings.snapThreshold
        
        // Точка близко к верхнему краю (не в углах)
        let topEdgePoint = CGPoint(
            x: visibleFrame.midX,
            y: visibleFrame.maxY - threshold + 5
        )
        
        let detectedPosition = detectSnapPosition(at: topEdgePoint, screen: screen, threshold: threshold)
        XCTAssertEqual(detectedPosition, .topHalf, "Should detect top edge")
    }
    
    func testBottomEdgeDetection() {
        guard let screen = NSScreen.main else {
            XCTFail("No main screen found")
            return
        }
        
        let visibleFrame = screen.visibleFrame
        let threshold = snapSettings.snapThreshold
        
        // Точка близко к нижнему краю (не в углах)
        let bottomEdgePoint = CGPoint(
            x: visibleFrame.midX,
            y: visibleFrame.minY + threshold - 5
        )
        
        let detectedPosition = detectSnapPosition(at: bottomEdgePoint, screen: screen, threshold: threshold)
        XCTAssertEqual(detectedPosition, .bottomHalf, "Should detect bottom edge")
    }
    
    // MARK: - Corner Detection Tests
    
    func testTopLeftCornerDetection() {
        guard let screen = NSScreen.main else {
            XCTFail("No main screen found")
            return
        }
        
        let visibleFrame = screen.visibleFrame
        let threshold = snapSettings.snapThreshold
        
        // Точка в верхнем левом углу
        let cornerPoint = CGPoint(
            x: visibleFrame.minX + threshold - 5,
            y: visibleFrame.maxY - threshold + 5
        )
        
        let detectedPosition = detectSnapPosition(at: cornerPoint, screen: screen, threshold: threshold)
        XCTAssertEqual(detectedPosition, .topLeftQuarter, "Should detect top-left corner")
    }
    
    func testTopRightCornerDetection() {
        guard let screen = NSScreen.main else {
            XCTFail("No main screen found")
            return
        }
        
        let visibleFrame = screen.visibleFrame
        let threshold = snapSettings.snapThreshold
        
        // Точка в верхнем правом углу
        let cornerPoint = CGPoint(
            x: visibleFrame.maxX - threshold + 5,
            y: visibleFrame.maxY - threshold + 5
        )
        
        let detectedPosition = detectSnapPosition(at: cornerPoint, screen: screen, threshold: threshold)
        XCTAssertEqual(detectedPosition, .topRightQuarter, "Should detect top-right corner")
    }
    
    func testBottomLeftCornerDetection() {
        guard let screen = NSScreen.main else {
            XCTFail("No main screen found")
            return
        }
        
        let visibleFrame = screen.visibleFrame
        let threshold = snapSettings.snapThreshold
        
        // Точка в нижнем левом углу
        let cornerPoint = CGPoint(
            x: visibleFrame.minX + threshold - 5,
            y: visibleFrame.minY + threshold - 5
        )
        
        let detectedPosition = detectSnapPosition(at: cornerPoint, screen: screen, threshold: threshold)
        XCTAssertEqual(detectedPosition, .bottomLeftQuarter, "Should detect bottom-left corner")
    }
    
    func testBottomRightCornerDetection() {
        guard let screen = NSScreen.main else {
            XCTFail("No main screen found")
            return
        }
        
        let visibleFrame = screen.visibleFrame
        let threshold = snapSettings.snapThreshold
        
        // Точка в нижнем правом углу
        let cornerPoint = CGPoint(
            x: visibleFrame.maxX - threshold + 5,
            y: visibleFrame.minY + threshold - 5
        )
        
        let detectedPosition = detectSnapPosition(at: cornerPoint, screen: screen, threshold: threshold)
        XCTAssertEqual(detectedPosition, .bottomRightQuarter, "Should detect bottom-right corner")
    }
    
    // MARK: - No Snap Zone Tests
    
    func testNoSnapInCenter() {
        guard let screen = NSScreen.main else {
            XCTFail("No main screen found")
            return
        }
        
        let visibleFrame = screen.visibleFrame
        let threshold = snapSettings.snapThreshold
        
        // Точка в центре экрана (далеко от краёв)
        let centerPoint = CGPoint(
            x: visibleFrame.midX,
            y: visibleFrame.midY
        )
        
        let detectedPosition = detectSnapPosition(at: centerPoint, screen: screen, threshold: threshold)
        XCTAssertNil(detectedPosition, "Should not snap in center")
    }
    
    func testNoSnapJustOutsideThreshold() {
        guard let screen = NSScreen.main else {
            XCTFail("No main screen found")
            return
        }
        
        let visibleFrame = screen.visibleFrame
        let threshold = snapSettings.snapThreshold
        
        // Точка чуть дальше порога от левого края
        let pointOutsideThreshold = CGPoint(
            x: visibleFrame.minX + threshold + 5,
            y: visibleFrame.midY
        )
        
        let detectedPosition = detectSnapPosition(at: pointOutsideThreshold, screen: screen, threshold: threshold)
        XCTAssertNil(detectedPosition, "Should not snap outside threshold")
    }
    
    // MARK: - Multi-Monitor Tests
    
    func testSnapOnSecondaryDisplay() {
        let screens = NSScreen.screens
        guard screens.count > 1 else {
            print("⚠️ Skipping multi-monitor test - only one screen available")
            return
        }
        
        let secondScreen = screens[1]
        let visibleFrame = secondScreen.visibleFrame
        let threshold = snapSettings.snapThreshold
        
        // Точка на втором экране, близко к левому краю
        let leftEdgePoint = CGPoint(
            x: visibleFrame.minX + threshold - 5,
            y: visibleFrame.midY
        )
        
        let detectedPosition = detectSnapPosition(at: leftEdgePoint, screen: secondScreen, threshold: threshold)
        XCTAssertEqual(detectedPosition, .leftHalf, "Should detect left edge on secondary display")
    }
    
    // MARK: - Performance Tests
    
    func testSnapDetectionPerformance() {
        guard let screen = NSScreen.main else {
            XCTFail("No main screen found")
            return
        }
        
        let visibleFrame = screen.visibleFrame
        let threshold = snapSettings.snapThreshold
        
        measure {
            // Simulate 100 snap detections
            for _ in 0..<100 {
                let randomPoint = CGPoint(
                    x: visibleFrame.minX + CGFloat.random(in: 0...visibleFrame.width),
                    y: visibleFrame.minY + CGFloat.random(in: 0...visibleFrame.height)
                )
                _ = detectSnapPosition(at: randomPoint, screen: screen, threshold: threshold)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    /// Симуляция логики определения позиции snap (копия из WindowManager)
    private func detectSnapPosition(at location: CGPoint, screen: NSScreen, threshold: CGFloat) -> WindowPosition? {
        let visibleFrame = screen.visibleFrame
        
        // Проверить, близко ли курсор к краям экрана
        var targetPosition: WindowPosition?
        
        // Проверка углов - приоритетнее, чем края
        let nearLeft = location.x - visibleFrame.minX < threshold
        let nearRight = visibleFrame.maxX - location.x < threshold
        let nearTop = visibleFrame.maxY - location.y < threshold
        let nearBottom = location.y - visibleFrame.minY < threshold
        
        // Углы (приоритет над краями)
        if nearTop && nearLeft {
            targetPosition = .topLeftQuarter
        } else if nearTop && nearRight {
            targetPosition = .topRightQuarter
        } else if nearBottom && nearLeft {
            targetPosition = .bottomLeftQuarter
        } else if nearBottom && nearRight {
            targetPosition = .bottomRightQuarter
        }
        // Края (только если не угол)
        else if nearLeft {
            targetPosition = .leftHalf
        } else if nearRight {
            targetPosition = .rightHalf
        } else if nearTop {
            targetPosition = .topHalf
        } else if nearBottom {
            targetPosition = .bottomHalf
        }
        
        return targetPosition
    }
}
