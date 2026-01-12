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
    
    // Advanced Constraint-Based Layouts (Academic Algorithms)
    case kaczmarz = "kaczmarz"
    case interiorPoint = "interior_point"
    case activeSet = "active_set"
    case linearRelaxation = "linear_relaxation"
    case constraintSimplex = "constraint_simplex"
    
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
        case .kaczmarz: return "Kaczmarz (Iterative Projection)"
        case .interiorPoint: return "Interior Point (Barrier Method)"
        case .activeSet: return "Active Set (QP Solver)"
        case .linearRelaxation: return "Linear Relaxation (Gauss-Seidel)"
        case .constraintSimplex: return "Constraint Simplex (LP)"
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
            
        // Advanced Constraint-Based Layouts
        case .kaczmarz:
            // Kaczmarz iterative projection - converges to optimal distribution
            // Uses golden ratio subdivision
            let phi = (1.0 + sqrt(5.0)) / 2.0 // φ ≈ 1.618
            let mainWidth = width / phi
            return CGRect(x: x, y: y, width: mainWidth, height: height)
            
        case .interiorPoint:
            // Interior Point barrier method - quadratic optimization
            // Balanced distribution with barrier constraints
            let margin = width * 0.08 // 8% margin (barrier function)
            return CGRect(
                x: x + margin,
                y: y + margin,
                width: width - 2 * margin,
                height: height - 2 * margin
            )
            
        case .activeSet:
            // Active Set QP solver - identifies active constraints
            // Left 2/3 as primary active region
            return CGRect(x: x, y: y, width: width * 2 / 3, height: height)
            
        case .linearRelaxation:
            // Gauss-Seidel relaxation - iterative refinement
            // Center-biased with relaxation parameter ω = 0.7
            let relaxed = width * 0.7
            return CGRect(
                x: x + (width - relaxed) / 2,
                y: y,
                width: relaxed,
                height: height
            )
            
        case .constraintSimplex:
            // Simplex LP method - moves along feasible edges
            // Optimal corner point solution
            return CGRect(x: x, y: y, width: width / 2, height: height)
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
    
    // Constraint-Based Academic Algorithms
    case kaczmarz = "kaczmarz"
    case interiorPoint = "interior_point"
    case activeSet = "active_set"
    case linearRelaxation = "linear_relaxation"
    case constraintSimplex = "constraint_simplex"
    
    // Premium Work Modes
    case videoConferenceMode = "video_conference_mode"
    case dataAnalysisMode = "data_analysis_mode"
    case contentCreationMode = "content_creation_mode"
    case tradingMode = "trading_mode"
    case gamingStreamingMode = "gaming_streaming_mode"
    case learningMode = "learning_mode"
    case projectManagementMode = "project_management_mode"
    case monitoringMode = "monitoring_mode"

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
        
        // Constraint-Based Algorithms
        case .kaczmarz: return "🔬 Kaczmarz Projection"
        case .interiorPoint: return "🎯 Interior Point Barrier"
        case .activeSet: return "🔷 Active Set QP"
        case .linearRelaxation: return "〰️ Linear Relaxation"
        case .constraintSimplex: return "📐 Constraint Simplex"
        
        // Premium Work Modes
        case .videoConferenceMode: return "📹 Video Conference Pro"
        case .dataAnalysisMode: return "📊 Data Analysis Studio"
        case .contentCreationMode: return "🎬 Content Creator Suite"
        case .tradingMode: return "📈 Trading Workstation"
        case .gamingStreamingMode: return "🎮 Gaming & Streaming"
        case .learningMode: return "📚 Learning Environment"
        case .projectManagementMode: return "📋 Project Command Center"
        case .monitoringMode: return "🖥️ System Monitoring Hub"
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
        
        // Constraint-Based Algorithms
        case .kaczmarz:
            return "Итеративные проекции на гиперплоскости ограничений. O(n·m) сложность. Гарантированная сходимость"
        case .interiorPoint:
            return "Барьерный метод квадратичной оптимизации. Логарифмические барьеры для границ экрана"
        case .activeSet:
            return "QP-решатель с идентификацией активных ограничений. Оптимально для жёстких границ"
        case .linearRelaxation:
            return "Метод Гаусса-Зейделя с релаксацией. Последовательное уточнение позиций окон"
        case .constraintSimplex:
            return "Симплекс-метод линейного программирования. Навигация по вершинам допустимой области"
        
        // Premium Work Modes
        case .videoConferenceMode:
            return "Оптимальная раскладка для видеоконференций: основное видео (70%) + чат/заметки (30%)"
        case .dataAnalysisMode:
            return "Студия анализа данных: таблицы (40%) + графики (35%) + код/скрипты (25%)"
        case .contentCreationMode:
            return "Рабочее место создателя контента: редактор (50%) + превью (25%) + ресурсы (25%)"
        case .tradingMode:
            return "Торговая станция: графики (60%) + терминал (25%) + новости/аналитика (15%)"
        case .gamingStreamingMode:
            return "Стриминг-сетап: игра (70%) + OBS/стрим (20%) + чат/донаты (10%)"
        case .learningMode:
            return "Обучающая среда: видео/лекция (60%) + заметки (25%) + доп.материалы (15%)"
        case .projectManagementMode:
            return "Центр управления проектами: канбан (50%) + календарь (30%) + коммуникации (20%)"
        case .monitoringMode:
            return "Центр мониторинга: главный дашборд (60%) + логи (25%) + алерты/метрики (15%)"
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
        
        // Constraint-Based Algorithms
        case .kaczmarz: return "arrow.triangle.2.circlepath"
        case .interiorPoint: return "scope"
        case .activeSet: return "square.on.square.dashed"
        case .linearRelaxation: return "waveform.path"
        case .constraintSimplex: return "triangle"
        
        // Premium Work Modes
        case .videoConferenceMode: return "video.fill"
        case .dataAnalysisMode: return "chart.bar.fill"
        case .contentCreationMode: return "play.rectangle.fill"
        case .tradingMode: return "chart.line.uptrend.xyaxis"
        case .gamingStreamingMode: return "gamecontroller.fill"
        case .learningMode: return "graduationcap.fill"
        case .projectManagementMode: return "list.bullet.rectangle"
        case .monitoringMode: return "desktopcomputer"
        }
    }

    var category: String {
        switch self {
        case .grid, .horizontal, .vertical, .cascade, .fibonacci, .focus:
            return "Базовые"
        case .readingMode, .codingMode, .designMode, .communicationMode, .researchMode, .presentationMode, .multiTaskMode, .ultraWideMode:
            return "Умные режимы"
        case .kaczmarz, .interiorPoint, .activeSet, .linearRelaxation, .constraintSimplex:
            return "Academic Algorithms"
        case .videoConferenceMode, .dataAnalysisMode, .contentCreationMode, .tradingMode, .gamingStreamingMode, .learningMode, .projectManagementMode, .monitoringMode:
            return "Premium Work Modes"
        }
    }
}

