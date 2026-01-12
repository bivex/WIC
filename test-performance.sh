#!/bin/bash

echo "🚀 WIC Performance Comparison Test"
echo "====================================="
echo ""
echo "This script will test optimized vs non-optimized performance"
echo ""

# Цвета
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Функция для измерения startup time
measure_startup() {
    local mode=$1
    echo -e "${BLUE}Testing ${mode} startup time...${NC}"
    
    local total_time=0
    local iterations=5
    
    for i in $(seq 1 $iterations); do
        # Запуск и немедленная остановка
        local start=$(date +%s%N)
        timeout 2s .build/$mode/WIC > /dev/null 2>&1 &
        local pid=$!
        sleep 0.5
        kill $pid 2>/dev/null
        local end=$(date +%s%N)
        
        local elapsed=$(( ($end - $start) / 1000000 ))
        total_time=$(( $total_time + $elapsed ))
        echo "  Run $i: ${elapsed}ms"
    done
    
    local avg=$(( $total_time / $iterations ))
    echo -e "${GREEN}  Average: ${avg}ms${NC}"
    echo ""
    
    return $avg
}

echo "📦 Building both versions..."
echo ""

# Собираем debug и release
echo "Building Debug..."
swift build --configuration debug > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Debug build failed${NC}"
    exit 1
fi

echo "Building Release..."
swift build --configuration release > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Release build failed${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Both builds complete${NC}"
echo ""
echo "======================================"
echo ""

# Сравнение startup time
echo -e "${YELLOW}📊 Startup Time Comparison${NC}"
echo ""

measure_startup "debug"
debug_time=$?

measure_startup "release"
release_time=$?

echo "======================================"
echo -e "${YELLOW}📈 Results${NC}"
echo ""
echo -e "  Debug:   ${debug_time}ms"
echo -e "  Release: ${release_time}ms"

if [ $release_time -lt $debug_time ]; then
    improvement=$(( ($debug_time - $release_time) * 100 / $debug_time ))
    echo -e "  ${GREEN}⚡ Release is ${improvement}% faster!${NC}"
else
    echo -e "  ${RED}⚠️  Unexpected: Release is slower${NC}"
fi

echo ""
echo "======================================"
echo ""
echo -e "${BLUE}💡 To test with Instruments:${NC}"
echo "  instruments -t 'Time Profiler' .build/release/WIC"
echo ""
echo -e "${BLUE}💡 To compare memory usage:${NC}"
echo "  instruments -t 'Allocations' .build/release/WIC"
echo ""
echo "✅ Performance test complete!"
