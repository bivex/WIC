#!/bin/bash

echo "🔬 WIC Performance Profiler"
echo "=============================="
echo ""

# Очистка предыдущих сборок
echo "🧹 Cleaning previous builds..."
swift package clean

# Сборка с оптимизациями и профилированием
echo "⚙️  Building with Release optimizations + profiling..."
swift build \
    --configuration release \
    -Xswiftc -profile-generate \
    -Xswiftc -profile-coverage-mapping \
    -Xswiftc -enable-testing

if [ $? -ne 0 ]; then
    echo "❌ Build failed"
    exit 1
fi

echo ""
echo "✅ Build complete!"
echo ""
echo "📊 Collecting baseline performance metrics..."
echo ""

# Запуск с измерением времени
echo "Starting WIC with profiling..."
echo "Press Cmd+C after testing auto-layouts"
echo ""

# Запуск с time
time .build/release/WIC &
WIC_PID=$!

echo ""
echo "🔍 WIC running with PID: $WIC_PID"
echo ""
echo "📝 Instructions:"
echo "   1. Test auto-layout operations (Grid, Focus, etc.)"
echo "   2. Press Cmd+C when done"
echo "   3. Check the logs for performance metrics"
echo ""

# Ожидание завершения
wait $WIC_PID

echo ""
echo "🎯 Profiling complete! Check console output above."
