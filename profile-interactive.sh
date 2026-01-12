#!/bin/bash

echo "🔬 WIC Performance Profiler"
echo "================================"
echo ""
echo "📝 Instructions:"
echo "  1. Application will start"
echo "  2. Test these operations:"
echo "     - Grid Layout (Cmd+Opt+L)"
echo "     - Horizontal Layout (menu)"
echo "     - Fibonacci Layout (menu)"
echo "     - Focus Layout (Cmd+Opt+Shift+L)"
echo "  3. Press Ctrl+C when done"
echo ""
echo "Starting in 3 seconds..."
sleep 3

# Запуск с выводом метрик
swift run 2>&1 | tee /tmp/wic_profile.log

echo ""
echo "================================"
echo "📊 Performance Summary"
echo "================================"
echo ""

# Анализ собранных данных
echo "⏱️  Operation Times:"
grep "Completed:" /tmp/wic_profile.log | awk '{
    operation = $0
    gsub(/.*Completed: /, "", operation)
    gsub(/ in.*/, "", operation)
    time = $0
    gsub(/.* in /, "", time)
    gsub(/ms.*/, "", time)
    print "  " operation ": " time "ms"
}' | sort -t: -k2 -n -r | head -15

echo ""
echo "🔍 Slowest Operations:"
grep "Completed:" /tmp/wic_profile.log | awk '{
    time = $0
    gsub(/.* in /, "", time)
    gsub(/ms.*/, "", time)
    operation = $0
    gsub(/.*Completed: /, "", operation)
    gsub(/ in.*/, "", operation)
    if (time > 100) print "  ⚠️  " operation ": " time "ms"
    else if (time > 50) print "  ⚡ " operation ": " time "ms"
    else print "  ✅ " operation ": " time "ms"
}' | head -20

echo ""
echo "📈 Statistics:"
grep "Found.*window" /tmp/wic_profile.log | tail -5
echo ""
grep "display(s)" /tmp/wic_profile.log | head -1

echo ""
echo "✅ Profile complete! Full log saved to /tmp/wic_profile.log"
