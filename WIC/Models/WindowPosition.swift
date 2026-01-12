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
    var gridPadding: CGFloat = 10 // Отступ сетки от краёв экрана
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

// MARK: - Auto Layout Types

/// Типы автоматической раскладки окон
enum AutoLayoutType: String, CaseIterable, Identifiable {
    // Базовые режимы
    case grid = "grid"
    case horizontal = "horizontal"
    case vertical = "vertical"
    case cascade = "cascade"
    case fibonacci = "fibonacci"
    case focus = "focus"

    // Умные режимы (Smart Modes - BookingExpert UI)
    case readingMode = "reading_mode"
    case codingMode = "coding_mode"
    case designMode = "design_mode"
    case communicationMode = "communication_mode"
    case researchMode = "research_mode"
    case presentationMode = "presentation_mode"
    case multiTaskMode = "multitask_mode"
    case ultraWideMode = "ultrawide_mode"

    var id: String { self.rawValue }

    var displayName: String {
        switch self {
        // Базовые режимы
        case .grid: return "Сетка"
        case .horizontal: return "Горизонтально"
        case .vertical: return "Вертикально"
        case .cascade: return "Каскад"
        case .fibonacci: return "Фибоначчи"
        case .focus: return "Фокус"

        // Умные режимы
        case .readingMode: return "📖 Режим чтения"
        case .codingMode: return "💻 Режим кодирования"
        case .designMode: return "🎨 Режим дизайна"
        case .communicationMode: return "💬 Режим общения"
        case .researchMode: return "🔬 Режим исследования"
        case .presentationMode: return "📊 Режим презентации"
        case .multiTaskMode: return "⚡ Многозадачность"
        case .ultraWideMode: return "🖥️ Ультраширокий"
        }
    }

    var description: String {
        switch self {
        // Базовые режимы
        case .grid:
            return "Равномерная сетка окон на экране"
        case .horizontal:
            return "Окна расположены горизонтально друг за другом"
        case .vertical:
            return "Окна расположены вертикально одно под другим"
        case .cascade:
            return "Окна расположены каскадом с небольшим смещением"
        case .fibonacci:
            return "Золотое сечение - одно большое окно, остальные по спирали"
        case .focus:
            return "Главное окно занимает 2/3, остальные делят 1/3"

        // Умные режимы
        case .readingMode:
            return "Оптимальная ширина для чтения (65-75 символов). Центральное окно идеально для документов, статей, книг"
        case .codingMode:
            return "Редактор (60%) + терминал/консоль (40%). Вертикальное разделение для эффективной разработки"
        case .designMode:
            return "Большой canvas (70%) + боковая панель инструментов (30%). Идеально для Figma, Photoshop, Sketch"
        case .communicationMode:
            return "Видеозвонок (основное окно) + чат/заметки сбоку. Оптимально для встреч и коммуникации"
        case .researchMode:
            return "4 окна в квадранты. Идеально для сравнения источников, анализа данных, написания с несколькими ссылками"
        case .presentationMode:
            return "Главное окно (презентация/слайды) + вспомогательные заметки внизу. Режим докладчика"
        case .multiTaskMode:
            return "Адаптивное распределение по количеству окон. Максимальная эффективность использования пространства"
        case .ultraWideMode:
            return "Оптимизация для ультраширокого экрана (21:9, 32:9). Три колонки с основным контентом в центре"
        }
    }

    var iconName: String {
        switch self {
        // Базовые режимы
        case .grid: return "square.grid.2x2"
        case .horizontal: return "rectangle.split.3x1"
        case .vertical: return "rectangle.split.1x2"
        case .cascade: return "square.stack.3d.up"
        case .fibonacci: return "square.grid.3x1.folder.badge.plus"
        case .focus: return "sidebar.left"

        // Умные режимы
        case .readingMode: return "book.fill"
        case .codingMode: return "chevron.left.forwardslash.chevron.right"
        case .designMode: return "paintbrush.fill"
        case .communicationMode: return "person.2.fill"
        case .researchMode: return "magnifyingglass.circle.fill"
        case .presentationMode: return "rectangle.on.rectangle.angled"
        case .multiTaskMode: return "square.grid.3x3.fill"
        case .ultraWideMode: return "rectangle.expand.vertical"
        }
    }

    var category: String {
        switch self {
        case .grid, .horizontal, .vertical, .cascade, .fibonacci, .focus:
            return "Базовые"
        case .readingMode, .codingMode, .designMode, .communicationMode, .researchMode, .presentationMode, .multiTaskMode, .ultraWideMode:
            return "Умные режимы"
        }
    }
}

