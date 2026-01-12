#!/usr/bin/env swift

import Foundation
import Darwin

// ANSI цвета
let RESET = "\u{001B}[0m"
let RED = "\u{001B}[31m"
let GREEN = "\u{001B}[32m"
let YELLOW = "\u{001B}[33m"
let BLUE = "\u{001B}[34m"
let MAGENTA = "\u{001B}[35m"
let CYAN = "\u{001B}[36m"

print("\(CYAN)🔬 WIC Performance Benchmark\(RESET)")
print(String(repeating: "=", count: 50))
print()

// Функция для замера времени выполнения
func measureTime(_ name: String, block: () -> Void) -> TimeInterval {
    let start = Date()
    block()
    let elapsed = Date().timeIntervalSince(start)
    return elapsed
}

// Функция для форматирования времени
func formatTime(_ seconds: TimeInterval) -> String {
    if seconds < 0.001 {
        return String(format: "%.3fμs", seconds * 1_000_000)
    } else if seconds < 1.0 {
        return String(format: "%.3fms", seconds * 1000)
    } else {
        return String(format: "%.3fs", seconds)
    }
}

// Бенчмарк структура
struct BenchmarkResult {
    let name: String
    let time: TimeInterval
    let iterations: Int
    
    var avgTime: TimeInterval {
        return time / Double(iterations)
    }
}

// Парсинг логов WIC
func analyzeWICLogs() {
    print("\(YELLOW)📊 Analyzing WIC Performance Logs\(RESET)")
    print()
    
    let _ = FileManager.default.temporaryDirectory
        .appendingPathComponent("wic_benchmark.log")
    
    // Запуск WIC с перенаправлением в лог
    print("Starting WIC and collecting metrics...")
    print("(Will run for 5 seconds)")
    print()
    
    let task = Process()
    task.executableURL = URL(fileURLWithPath: "/Users/password9090/WIC/.build/debug/WIC")
    
    let pipe = Pipe()
    task.standardOutput = pipe
    task.standardError = pipe
    
    do {
        try task.run()
        
        // Даем приложению запуститься
        sleep(2)
        
        print("✅ WIC started. Collecting baseline metrics...")
        
        // Ждем еще немного для сбора данных
        sleep(3)
        
        // Останавливаем
        task.terminate()
        
        // Читаем вывод
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        if let output = String(data: data, encoding: .utf8) {
            parsePerformanceLogs(output)
        }
        
    } catch {
        print("\(RED)❌ Error running WIC: \(error)\(RESET)")
    }
}

// Парсинг производительности из логов
func parsePerformanceLogs(_ logs: String) {
    print()
    print("\(GREEN)📈 Performance Analysis\(RESET)")
    print(String(repeating: "=", count: 50))
    print()
    
    var operations: [String: [TimeInterval]] = [:]
    
    // Регулярка для поиска времени операций
    let pattern = #"Completed: (.*?) in ([0-9.]+)ms"#
    
    if let regex = try? NSRegularExpression(pattern: pattern) {
        let nsString = logs as NSString
        let results = regex.matches(in: logs, range: NSRange(logs.startIndex..., in: logs))
        
        for match in results {
            if match.numberOfRanges == 3 {
                let operationRange = match.range(at: 1)
                let timeRange = match.range(at: 2)
                
                let operation = nsString.substring(with: operationRange)
                if let timeString = Double(nsString.substring(with: timeRange)) {
                    let timeInSeconds = timeString / 1000.0
                    operations[operation, default: []].append(timeInSeconds)
                }
            }
        }
    }
    
    // Вывод статистики
    if operations.isEmpty {
        print("\(YELLOW)⚠️  No performance data collected yet\(RESET)")
        print("Run auto-layout operations to see metrics")
    } else {
        let sorted = operations.sorted { $0.value.reduce(0, +) > $1.value.reduce(0, +) }
        
        print("Top Operations by Total Time:")
        print()
        
        for (operation, times) in sorted.prefix(10) {
            let total = times.reduce(0, +)
            let avg = total / Double(times.count)
            let min = times.min() ?? 0
            let max = times.max() ?? 0
            
            print("  \(CYAN)\(operation)\(RESET)")
            print("    Calls: \(times.count)")
            print("    Total: \(formatTime(total))")
            print("    Avg:   \(formatTime(avg))")
            print("    Min:   \(formatTime(min))")
            print("    Max:   \(formatTime(max))")
            print()
        }
    }
}

// CPU и память
func systemMetrics() {
    print()
    print("\(MAGENTA)💻 System Metrics\(RESET)")
    print(String(repeating: "=", count: 50))
    print()
    
    // CPU info
    var size = 0
    sysctlbyname("hw.ncpu", nil, &size, nil, 0)
    var cpuCount = 0
    sysctlbyname("hw.ncpu", &cpuCount, &size, nil, 0)
    
    print("  CPU Cores: \(cpuCount)")
    
    // Memory
    var stats = vm_statistics64()
    var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64>.size / MemoryLayout<integer_t>.size)
    
    let result = withUnsafeMutablePointer(to: &stats) {
        $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
            host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
        }
    }
    
    if result == KERN_SUCCESS {
        let pageSize = vm_kernel_page_size
        let free = UInt64(stats.free_count) * UInt64(pageSize)
        let active = UInt64(stats.active_count) * UInt64(pageSize)
        
        print("  Free Memory:   \(free / 1_073_741_824) GB")
        print("  Active Memory: \(active / 1_073_741_824) GB")
    }
    
    print()
}

// Main
systemMetrics()
analyzeWICLogs()

print()
print("\(GREEN)✅ Benchmark Complete!\(RESET)")
print()
