#!/bin/bash

# Build and run WIC window manager
echo "Building WIC..."
swift build

if [ $? -eq 0 ]; then
    echo "Build successful! Running WIC..."
    echo "Press Cmd+C to stop"
    swift run
else
    echo "Build failed!"
    exit 1
fi
