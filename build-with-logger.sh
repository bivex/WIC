#!/bin/bash

echo "Building WIC with logger..."
cd /Users/password9090/WIC

# Clean build
rm -rf .build

# Build
swift build

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Build successful!"
    echo ""
    echo "To test logging, run: swift run"
    echo "Check console output for detailed timestamped logs"
else
    echo ""
    echo "❌ Build failed"
    exit 1
fi
