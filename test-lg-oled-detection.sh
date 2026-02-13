#!/bin/bash

# Test script for LG OLED 42" display detection
# This script demonstrates the enhanced display identification in WIC

echo "🔍 Testing LG OLED 42\" Display Detection"
echo "=========================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}📺 System Display Information:${NC}"
system_profiler SPDisplaysDataType | grep -E "(Display|Resolution|Vendor|Product|Serial|Year|Week)" | head -15
echo ""

echo -e "${BLUE}🧪 Running WIC Display Detection Tests:${NC}"
swift test --filter testLGOLED42Detection 2>&1 | grep -E "(Test Case|passed|failed|OLED)"
echo ""

echo -e "${BLUE}🏗️  Building WIC with display detection:${NC}"
swift build 2>&1 | tail -5
echo ""

echo -e "${BLUE}📊 Current Display Configuration in WIC:${NC}"
cat > /tmp/display_test.swift << 'EOF'
import Foundation
import CoreGraphics
import IOKit.graphics

// Get display information
var displayCount: UInt32 = 0
var activeDisplays = [CGDirectDisplayID](repeating: 0, count: 10)

guard CGGetActiveDisplayList(10, &activeDisplays, &displayCount) == .success else {
    print("❌ Failed to get display list")
    exit(1)
}

print("Total displays detected: \(displayCount)")
print("")

for i in 0..<Int(displayCount) {
    let displayID = activeDisplays[i]
    let bounds = CGDisplayBounds(displayID)
    let vendorID = CGDisplayVendorNumber(displayID)
    let productID = CGDisplayModelNumber(displayID)
    let serialNumber = CGDisplaySerialNumber(displayID)
    
    print("Display \(i + 1):")
    print("  Resolution: \(Int(bounds.width)) × \(Int(bounds.height))")
    print("  Vendor ID: 0x\(String(format: "%04X", vendorID))")
    print("  Product ID: 0x\(String(format: "%04X", productID))")
    print("  Serial: \(serialNumber)")
    
    // Check if it's LG OLED 42"
    let isLGVendor = vendorID == 0x1e6d
    let isOLED42ProductID = (productID >= 0xc0c8 && productID <= 0xc0ca) || 
                             productID == 0x0042 || productID == 0x0043
    let is4KResolution = (bounds.width >= 3840 && bounds.height >= 2160) ||
                         (bounds.width >= 2160 && bounds.height >= 3840)
    
    let isLGOLED42 = isLGVendor && (isOLED42ProductID || is4KResolution)
    
    if isLGOLED42 {
        print("  ✅ Detected as LG OLED 42\" - Optimizations enabled!")
    } else if isLGVendor {
        print("  📺 LG Display detected")
    }
    
    print("")
}
EOF

swift /tmp/display_test.swift
echo ""

echo -e "${GREEN}✅ LG OLED 42\" detection test complete!${NC}"
echo ""
echo "Features implemented:"
echo "  ✓ Vendor ID detection (LG = 0x1e6d)"
echo "  ✓ Product ID detection (0xc0c8-0xc0ca for OLED 42\")"
echo "  ✓ 4K resolution validation (3840×2160)"
echo "  ✓ Enhanced UI display with model name"
echo "  ✓ Automatic optimization flags for LG OLED displays"
echo "  ✓ Manufacturing date tracking"
echo "  ✓ Detailed logging for display detection"
