//
//  Logger.swift
//  WIC
//
//  Утилита для логирования с временными метками
//

import Foundation

class Logger {
    static let shared = Logger()
    
    private var startTime: Date = Date()
    private let dateFormatter: DateFormatter
    private var lastOperationTime: Date?
    
    private init() {
        dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm:ss.SSS"
    }
    
    enum LogLevel: String {
        case debug = "🔍 DEBUG"
        case info = "ℹ️ INFO"
        case warning = "⚠️ WARNING"
        case error = "❌ ERROR"
        case performance = "⏱️ PERF"
    }
    
    /// Логировать сообщение с временной меткой
    func log(_ message: String, level: LogLevel = .info, function: String = #function, file: String = #file) {
        let timestamp = dateFormatter.string(from: Date())
        let fileName = (file as NSString).lastPathComponent
        let timeSinceStart = Date().timeIntervalSince(startTime)
        
        var deltaTime = ""
        if let lastTime = lastOperationTime {
            let delta = Date().timeIntervalSince(lastTime)
            deltaTime = String(format: " [Δ%.3fms]", delta * 1000)
        }
        lastOperationTime = Date()
        
        print("[\(timestamp)] \(level.rawValue) [\(fileName):\(function)] [+\(String(format: "%.3f", timeSinceStart))s\(deltaTime)] \(message)")
    }
    
    /// Засечь начало операции
    func startOperation(_ name: String) -> OperationTimer {
        log("Starting: \(name)", level: .performance)
        return OperationTimer(name: name, startTime: Date())
    }
    
    /// Сбросить таймер до текущего момента
    func resetTimer() {
        startTime = Date()
        lastOperationTime = nil
        log("Timer reset", level: .debug)
    }
}

/// Класс для замера времени выполнения операций
class OperationTimer {
    let name: String
    let startTime: Date
    
    init(name: String, startTime: Date) {
        self.name = name
        self.startTime = startTime
    }
    
    /// Завершить операцию и залогировать время
    func end() {
        let duration = Date().timeIntervalSince(startTime)
        Logger.shared.log("Completed: \(name) in \(String(format: "%.3fms", duration * 1000))", level: .performance)
    }
    
    deinit {
        // Автоматически логировать при выходе из области видимости
        let duration = Date().timeIntervalSince(startTime)
        Logger.shared.log("Auto-completed: \(name) in \(String(format: "%.3fms", duration * 1000))", level: .performance)
    }
}

/// Макрос для удобного логирования
extension Logger {
    func debug(_ message: String, function: String = #function, file: String = #file) {
        log(message, level: .debug, function: function, file: file)
    }
    
    func info(_ message: String, function: String = #function, file: String = #file) {
        log(message, level: .info, function: function, file: file)
    }
    
    func warning(_ message: String, function: String = #function, file: String = #file) {
        log(message, level: .warning, function: function, file: file)
    }
    
    func error(_ message: String, function: String = #function, file: String = #file) {
        log(message, level: .error, function: function, file: file)
    }
    
    func perf(_ message: String, function: String = #function, file: String = #file) {
        log(message, level: .performance, function: function, file: file)
    }
}
