#!/usr/bin/env python3
"""
WIC Performance Analyzer
Анализирует логи производительности из WIC
"""

import re
import sys
from collections import defaultdict
from statistics import mean, median, stdev

# ANSI colors
RESET = "\033[0m"
RED = "\033[31m"
GREEN = "\033[32m"
YELLOW = "\033[33m"
BLUE = "\033[34m"
MAGENTA = "\033[35m"
CYAN = "\033[36m"
BOLD = "\033[1m"

def parse_logs(log_content):
    """Парсит логи WIC и извлекает метрики производительности"""
    
    operations = defaultdict(list)
    
    # Регулярки для разных типов логов
    completed_pattern = r"Completed: (.*?) in ([0-9.]+)ms"
    window_pattern = r"Found (\d+) window\(s\)"
    display_pattern = r"initialized with (\d+) display\(s\)"
    
    for line in log_content.split('\n'):
        # Парсим завершенные операции
        match = re.search(completed_pattern, line)
        if match:
            operation = match.group(1)
            time_ms = float(match.group(2))
            operations[operation].append(time_ms)
    
    return operations

def format_time(ms):
    """Форматирует время в удобочитаемый вид"""
    if ms < 1:
        return f"{ms*1000:.1f}μs"
    elif ms < 1000:
        return f"{ms:.2f}ms"
    else:
        return f"{ms/1000:.2f}s"

def get_performance_rating(ms):
    """Возвращает рейтинг производительности"""
    if ms < 10:
        return f"{GREEN}⚡ Excellent{RESET}"
    elif ms < 50:
        return f"{BLUE}✅ Good{RESET}"
    elif ms < 100:
        return f"{YELLOW}⚠️  Moderate{RESET}"
    elif ms < 500:
        return f"{YELLOW}⏳ Slow{RESET}"
    else:
        return f"{RED}🐌 Very Slow{RESET}"

def print_header(text):
    """Печатает красивый заголовок"""
    print(f"\n{BOLD}{CYAN}{text}{RESET}")
    print("=" * 70)

def analyze_operations(operations):
    """Анализирует и выводит статистику операций"""
    
    if not operations:
        print(f"{YELLOW}⚠️  No performance data found{RESET}")
        return
    
    print_header("📊 WIC Performance Analysis")
    
    # Сортируем по средней времени
    sorted_ops = sorted(
        operations.items(),
        key=lambda x: mean(x[1]),
        reverse=True
    )
    
    print(f"\n{BOLD}Top Operations by Average Time:{RESET}\n")
    
    for i, (operation, times) in enumerate(sorted_ops[:15], 1):
        count = len(times)
        avg = mean(times)
        min_time = min(times)
        max_time = max(times)
        total = sum(times)
        std = stdev(times) if len(times) > 1 else 0
        
        rating = get_performance_rating(avg)
        
        print(f"{i:2d}. {BOLD}{operation}{RESET}")
        print(f"     Calls:  {count}")
        print(f"     Avg:    {format_time(avg):>10s}  {rating}")
        print(f"     Total:  {format_time(total):>10s}")
        print(f"     Range:  {format_time(min_time):>10s} - {format_time(max_time)}")
        if std > 0:
            print(f"     StdDev: {format_time(std):>10s}")
        print()
    
    # Общая статистика
    print_header("📈 Overall Statistics")
    
    total_operations = sum(len(times) for times in operations.values())
    total_time = sum(sum(times) for times in operations.values())
    unique_operations = len(operations)
    
    print(f"\n  Total Operations:     {total_operations}")
    print(f"  Unique Operations:    {unique_operations}")
    print(f"  Total Time:           {format_time(total_time)}")
    print(f"  Average per Call:     {format_time(total_time / total_operations)}")
    
    # Находим самые проблемные операции
    print_header("🔍 Performance Bottlenecks")
    
    bottlenecks = [(op, times) for op, times in sorted_ops if mean(times) > 100]
    
    if bottlenecks:
        print("\n  Operations taking > 100ms on average:\n")
        for op, times in bottlenecks[:5]:
            avg = mean(times)
            total = sum(times)
            percent = (total / total_time) * 100
            print(f"  {RED}⚠️  {op}{RESET}")
            print(f"      Avg: {format_time(avg)}, Total: {format_time(total)} ({percent:.1f}% of total time)")
            print()
    else:
        print(f"\n  {GREEN}✅ No significant bottlenecks detected!{RESET}")
    
    # Быстрые операции
    fast_ops = [(op, times) for op, times in sorted_ops if mean(times) < 10]
    if fast_ops:
        print(f"\n  {GREEN}⚡ Fast Operations (< 10ms):{RESET} {len(fast_ops)}")

def main():
    """Main function"""
    
    print(f"{CYAN}{BOLD}")
    print("  ╔══════════════════════════════════════╗")
    print("  ║  🔬 WIC Performance Profiler        ║")
    print("  ╚══════════════════════════════════════╝")
    print(f"{RESET}")
    
    # Читаем логи из stdin или файла
    if len(sys.argv) > 1:
        with open(sys.argv[1], 'r') as f:
            log_content = f.read()
    else:
        print(f"{YELLOW}Reading from stdin... (paste logs and press Ctrl+D){RESET}\n")
        log_content = sys.stdin.read()
    
    operations = parse_logs(log_content)
    analyze_operations(operations)
    
    print(f"\n{GREEN}✅ Analysis complete!{RESET}\n")

if __name__ == "__main__":
    main()
