//
//  WindowPosition.swift
//  WIC
//
//  Модели для позиционирования окон
//

import Foundation
import CoreGraphics
import AppKit

/// Типы позиций окна на экране
enum WindowPosition: String, CaseIterable, Identifiable {
    case leftHalf = "left_half"
    case rightHalf = "right_half"
    case topHalf = "top_half"
    case bottomHalf = "bottom_half"
    
    case topLeftQuarter = "top_left_quarter"
    case topRightQuarter = "top_right_quarter"
    case bottomLeftQuarter = "bottom_left_quarter"
    case bottomRightQuarter = "bottom_right_quarter"
    
    case leftThird = "left_third"
    case centerThird = "center_third"
    case rightThird = "right_third"
    
    case leftTwoThirds = "left_two_thirds"
    case rightTwoThirds = "right_two_thirds"
    
    case center = "center"
    case maximize = "maximize"
    
    var id: String { self.rawValue }
    
    var displayName: String {
        switch self {
        case .leftHalf: return "Левая половина"
        case .rightHalf: return "Правая половина"
        case .topHalf: return "Верхняя половина"
        case .bottomHalf: return "Нижняя половина"
        case .topLeftQuarter: return "Левая верхняя четверть"
        case .topRightQuarter: return "Правая верхняя четверть"
        case .bottomLeftQuarter: return "Левая нижняя четверть"
        case .bottomRightQuarter: return "Правая нижняя четверть"
        case .leftThird: return "Левая треть"
        case .centerThird: return "Центральная треть"
        case .rightThird: return "Правая треть"
        case .leftTwoThirds: return "Левые две трети"
        case .rightTwoThirds: return "Правые две трети"
        case .center: return "Центр"
        case .maximize: return "Максимизировать"
        }
    }
    
    /// Вычислить frame для данной позиции на указанном экране
    func calculateFrame(for screen: NSScreen) -> CGRect {
        let visibleFrame = screen.visibleFrame
        let x = visibleFrame.origin.x
        let y = visibleFrame.origin.y
        let width = visibleFrame.width
        let height = visibleFrame.height
        
        switch self {
        case .leftHalf:
            return CGRect(x: x, y: y, width: width / 2, height: height)
        case .rightHalf:
            return CGRect(x: x + width / 2, y: y, width: width / 2, height: height)
        case .topHalf:
            return CGRect(x: x, y: y + height / 2, width: width, height: height / 2)
        case .bottomHalf:
            return CGRect(x: x, y: y, width: width, height: height / 2)
            
        case .topLeftQuarter:
            return CGRect(x: x, y: y + height / 2, width: width / 2, height: height / 2)
        case .topRightQuarter:
            return CGRect(x: x + width / 2, y: y + height / 2, width: width / 2, height: height / 2)
        case .bottomLeftQuarter:
            return CGRect(x: x, y: y, width: width / 2, height: height / 2)
        case .bottomRightQuarter:
            return CGRect(x: x + width / 2, y: y, width: width / 2, height: height / 2)
            
        case .leftThird:
            return CGRect(x: x, y: y, width: width / 3, height: height)
        case .centerThird:
            return CGRect(x: x + width / 3, y: y, width: width / 3, height: height)
        case .rightThird:
            return CGRect(x: x + width * 2 / 3, y: y, width: width / 3, height: height)
            
        case .leftTwoThirds:
            return CGRect(x: x, y: y, width: width * 2 / 3, height: height)
        case .rightTwoThirds:
            return CGRect(x: x + width / 3, y: y, width: width * 2 / 3, height: height)
            
        case .center:
            let centeredWidth = width * 0.7
            let centeredHeight = height * 0.7
            return CGRect(
                x: x + (width - centeredWidth) / 2,
                y: y + (height - centeredHeight) / 2,
                width: centeredWidth,
                height: centeredHeight
            )
            
        case .maximize:
            return visibleFrame
        }
    }
}

/// Настройки автоматического snap
struct SnapSettings {
    var isEnabled: Bool = true
    var snapThreshold: CGFloat = 20 // Пиксели от края экрана
    var animationDuration: Double = 0.2
}

/// Информация о дисплее
struct DisplayInfo: Identifiable {
    let id: CGDirectDisplayID
    let name: String
    let frame: CGRect
    let isVertical: Bool
    
    static func getAllDisplays() -> [DisplayInfo] {
        var displays: [DisplayInfo] = []
        var displayCount: UInt32 = 0
        var activeDisplays = [CGDirectDisplayID](repeating: 0, count: 10)
        
        guard CGGetActiveDisplayList(10, &activeDisplays, &displayCount) == .success else {
            return displays
        }
        
        for i in 0..<Int(displayCount) {
            let displayID = activeDisplays[i]
            let bounds = CGDisplayBounds(displayID)
            let isVertical = bounds.height > bounds.width
            
            displays.append(DisplayInfo(
                id: displayID,
                name: "Display \(i + 1)",
                frame: bounds,
                isVertical: isVertical
            ))
        }
        
        return displays
    }
}
