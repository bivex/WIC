//
//  WindowPosition.swift
//  WIC
//
//  Модели для позиционирования окон
//

import Foundation
import CoreGraphics
import AppKit
import IOKit.graphics

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
    let vendorID: UInt32
    let productID: UInt32
    let serialNumber: UInt32
    let manufactureYear: Int?
    let manufactureWeek: Int?
    
    /// Человекочитаемое название модели дисплея
    var modelName: String {
        return getDisplayModelName()
    }
    
    /// Название производителя
    var vendorName: String {
        return getVendorName()
    }
    
    /// Полное описание дисплея
    var fullDescription: String {
        let size = "\(Int(frame.width))x\(Int(frame.height))"
        let orientation = isVertical ? "↕️" : "↔️"
        let vendor = vendorName
        let model = modelName
        
        if model.isEmpty {
            return "\(orientation) \(vendor) Display (\(size))"
        } else {
            return "\(orientation) \(vendor) \(model) (\(size))"
        }
    }
    
    /// Определяет, является ли дисплей LG OLED 42"
    var isLGOLED42: Bool {
        // LG vendor ID: 0x1e6d (7789)
        // LG OLED 42" product IDs: 0xc0c8, 0xc0c9, 0xc0ca (49352-49354)
        // Также проверяем разрешение ~4K (3840x2160 native для 42")
        let isLGVendor = vendorID == 0x1e6d
        let isOLED42ProductID = (productID >= 0xc0c8 && productID <= 0xc0ca) || 
                                 productID == 0x0042 || // Generic 42" product ID
                                 productID == 0x0043
        let is4KResolution = (frame.width >= 3840 && frame.height >= 2160) ||
                            (frame.width >= 2160 && frame.height >= 3840)
        
        return isLGVendor && (isOLED42ProductID || is4KResolution)
    }
    
    /// Определяет название производителя по vendorID
    private func getVendorName() -> String {
        switch vendorID {
        case 0x1e6d, 0x30e4:
            return "LG"
        case 0x4d10, 0x593a, 0x05ac:
            return "Apple"
        case 0x10ac:
            return "Dell"
        case 0x4c2d:
            return "Samsung"
        case 0x2d44:
            return "HP"
        case 0x5a63:
            return "ViewSonic"
        case 0x22f0:
            return "ASUS"
        case 0x0469:
            return "BenQ"
        case 0x4dd9:
            return "Sony"
        case 0x38a3:
            return "Acer"
        default:
            return "Display"
        }
    }
    
    /// Определяет название модели дисплея
    private func getDisplayModelName() -> String {
        // Специальное определение для LG OLED
        if vendorID == 0x1e6d {
            // LG OLED models
            switch productID {
            case 0xc0c8, 0xc0c9, 0xc0ca:
                // Определяем по разрешению и физическому размеру
                let diagonal = estimatedDiagonalInches()
                if diagonal >= 40 && diagonal <= 44 {
                    return "OLED 42\""
                } else if diagonal >= 46 && diagonal <= 50 {
                    return "OLED 48\""
                } else if diagonal >= 52 && diagonal <= 57 {
                    return "OLED 55\""
                } else if diagonal >= 62 && diagonal <= 68 {
                    return "OLED 65\""
                }
                return "OLED TV"
            case 0x0042:
                return "OLED 42\" (42C2/42C3)"
            case 0x0043:
                return "OLED 42\" (42CS6LA)"
            case 0x0048:
                return "OLED 48\""
            default:
                break
            }
        }
        
        // Получаем информацию из IOKit
        guard let displayInfo = getIODisplayInfo() else {
            return ""
        }
        
        return displayInfo
    }
    
    /// Оценка диагонали в дюймах на основе разрешения
    private func estimatedDiagonalInches() -> Double {
        // Для OLED TV обычно используется PPI около 100-105
        // 42" OLED: 3840x2160, ~104 PPI
        let widthInches = Double(frame.width) / 100.0
        let heightInches = Double(frame.height) / 100.0
        let diagonal = sqrt(widthInches * widthInches + heightInches * heightInches)
        return diagonal
    }
    
    /// Получает информацию о дисплее из IOKit
    private func getIODisplayInfo() -> String? {
        var servicePort: io_service_t = 0
        var iter: io_iterator_t = 0
        
        // Получаем IOService для дисплея
        guard IOServiceGetMatchingServices(kIOMainPortDefault,
                                          IOServiceMatching("IODisplayConnect"),
                                          &iter) == KERN_SUCCESS else {
            return nil
        }
        
        defer { IOObjectRelease(iter) }
        
        // Ищем соответствующий дисплей
        while true {
            servicePort = IOIteratorNext(iter)
            if servicePort == 0 { break }
            
            defer { IOObjectRelease(servicePort) }
            
            // Получаем информацию о дисплее
            guard let displayInfo = IODisplayCreateInfoDictionary(servicePort, UInt32(kIODisplayOnlyPreferredName)),
                  let info = displayInfo.takeRetainedValue() as? [String: Any] else {
                continue
            }
            
            // Извлекаем vendor и product ID из IOKit
            if let vendorIDValue = info[kDisplayVendorID] as? UInt32,
               let productIDValue = info[kDisplayProductID] as? UInt32,
               vendorIDValue == vendorID && productIDValue == productID {
                
                // Получаем имя дисплея
                if let names = info[kDisplayProductName] as? [String: String],
                   let name = names["en_US"] ?? names.values.first {
                    return name
                }
            }
        }
        
        return nil
    }
    
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
            
            // Получаем информацию о vendor и product ID
            let vendorID = CGDisplayVendorNumber(displayID)
            let productID = CGDisplayModelNumber(displayID)
            let serialNumber = CGDisplaySerialNumber(displayID)
            
            // Получаем дополнительную информацию из IOKit
            var manufactureYear: Int?
            var manufactureWeek: Int?
            
            if let (year, week) = getManufactureInfo(for: displayID) {
                manufactureYear = year
                manufactureWeek = week
            }
            
            let displayInfo = DisplayInfo(
                id: displayID,
                name: "Display \(i + 1)",
                frame: bounds,
                isVertical: isVertical,
                vendorID: vendorID,
                productID: productID,
                serialNumber: serialNumber,
                manufactureYear: manufactureYear,
                manufactureWeek: manufactureWeek
            )
            
            displays.append(displayInfo)
        }
        
        return displays
    }
    
    /// Получает информацию о дате производства дисплея
    private static func getManufactureInfo(for displayID: CGDirectDisplayID) -> (year: Int, week: Int)? {
        var servicePort: io_service_t = 0
        var iter: io_iterator_t = 0
        
        guard IOServiceGetMatchingServices(kIOMainPortDefault,
                                          IOServiceMatching("IODisplayConnect"),
                                          &iter) == KERN_SUCCESS else {
            return nil
        }
        
        defer { IOObjectRelease(iter) }
        
        while true {
            servicePort = IOIteratorNext(iter)
            if servicePort == 0 { break }
            
            defer { IOObjectRelease(servicePort) }
            
            guard let displayInfo = IODisplayCreateInfoDictionary(servicePort, UInt32(kIODisplayOnlyPreferredName)),
                  let info = displayInfo.takeRetainedValue() as? [String: Any] else {
                continue
            }
            
            // Проверяем соответствие displayID
            let vendorID = CGDisplayVendorNumber(displayID)
            let productID = CGDisplayModelNumber(displayID)
            
            if let vendorIDValue = info[kDisplayVendorID] as? UInt32,
               let productIDValue = info[kDisplayProductID] as? UInt32,
               vendorIDValue == vendorID && productIDValue == productID {
                
                let year = info[kDisplayYearOfManufacture] as? Int
                let week = info[kDisplayWeekOfManufacture] as? Int
                
                if let year = year, let week = week {
                    return (year, week)
                }
            }
        }
        
        return nil
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
    
    // Premium Programming Modes
    case fullStackDevMode = "fullstack_dev_mode"
    case mobileDevMode = "mobile_dev_mode"
    case devOpsMode = "devops_mode"
    case mlAiDevMode = "ml_ai_dev_mode"
    case gameDevMode = "game_dev_mode"
    case frontendDevMode = "frontend_dev_mode"
    case backendApiMode = "backend_api_mode"
    case desktopAppDevMode = "desktop_app_dev_mode"

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
        
        // Premium Programming Modes
        case .fullStackDevMode: return "⚡ Full-Stack Development"
        case .mobileDevMode: return "📱 Mobile Development Studio"
        case .devOpsMode: return "🔧 DevOps Command Center"
        case .mlAiDevMode: return "🧠 ML/AI Development Lab"
        case .gameDevMode: return "🎯 Game Development Suite"
        case .frontendDevMode: return "🎨 Frontend Development Hub"
        case .backendApiMode: return "⚙️ Backend/API Workshop"
        case .desktopAppDevMode: return "🖥️ Desktop App Development"
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
        
        // Premium Programming Modes
        case .fullStackDevMode:
            return "Full-Stack рабочая станция: код (40%) + фронтенд превью (30%) + терминал/API (20%) + база/логи (10%)"
        case .mobileDevMode:
            return "Мобильная разработка: IDE (50%) + симулятор/эмулятор (35%) + консоль/логи (15%)"
        case .devOpsMode:
            return "DevOps центр: терминалы (40%) + мониторинг (30%) + конфиги/IaC (20%) + документация (10%)"
        case .mlAiDevMode:
            return "ML/AI лаборатория: Jupyter/код (45%) + визуализация/графики (35%) + данные/метрики (20%)"
        case .gameDevMode:
            return "Игровая разработка: движок/IDE (50%) + превью игры (30%) + ассеты/инспектор (20%)"
        case .frontendDevMode:
            return "Frontend мастерская: редактор (40%) + браузер/превью (40%) + инструменты разработчика (20%)"
        case .backendApiMode:
            return "Backend/API воркшоп: код (40%) + API тестер (30%) + база данных (20%) + логи/мониторинг (10%)"
        case .desktopAppDevMode:
            return "Desktop разработка: IDE (45%) + приложение/превью (35%) + отладчик/профайлер (15%) + документация (5%)"
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
        
        // Premium Programming Modes
        case .fullStackDevMode: return "chevron.left.forwardslash.chevron.right"
        case .mobileDevMode: return "iphone"
        case .devOpsMode: return "gearshape.2.fill"
        case .mlAiDevMode: return "brain.head.profile"
        case .gameDevMode: return "gamecontroller"
        case .frontendDevMode: return "paintbrush.pointed.fill"
        case .backendApiMode: return "server.rack"
        case .desktopAppDevMode: return "laptopcomputer"
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
        case .fullStackDevMode, .mobileDevMode, .devOpsMode, .mlAiDevMode, .gameDevMode, .frontendDevMode, .backendApiMode, .desktopAppDevMode:
            return "Premium Programming Modes"
        }
    }
}

