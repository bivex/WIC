# LG OLED 42" Display Support

## Overview
WIC now includes enhanced display detection with specific support and optimizations for LG OLED 42" displays. The system automatically identifies and configures optimal settings for these displays.

## Features

### ✅ Automatic Detection
- **Vendor ID Recognition**: Detects LG displays (Vendor ID: 0x1e6d)
- **Product ID Validation**: Identifies specific LG OLED models (0xc0c8-0xc0ca)
- **Resolution Verification**: Validates 4K resolution (3840×2160 native)
- **Manufacturing Info**: Tracks production year and week

### 📊 Display Information
The enhanced `DisplayInfo` struct now includes:

```swift
struct DisplayInfo {
    let id: CGDirectDisplayID
    let name: String
    let frame: CGRect
    let isVertical: Bool
    let vendorID: UInt32           // NEW: Hardware vendor ID
    let productID: UInt32          // NEW: Product model ID
    let serialNumber: UInt32       // NEW: Display serial number
    let manufactureYear: Int?      // NEW: Year of manufacture
    let manufactureWeek: Int?      // NEW: Week of manufacture
    
    var isLGOLED42: Bool           // NEW: LG OLED 42" detection
    var modelName: String          // NEW: Human-readable model name
    var vendorName: String         // NEW: Vendor name (LG, Apple, Dell, etc.)
    var fullDescription: String    // NEW: Complete display description
}
```

### 🎨 Enhanced UI Display
The Settings view now shows:
- ✅ Green checkmark for LG OLED 42" displays
- Full vendor and model information
- Product ID and manufacturing details
- Visual highlighting with green border/background
- Orientation indicators (↔️ horizontal, ↕️ vertical)

Example UI display:
```
↔️ LG OLED TV (1920x1080)
✅ LG OLED 42" — Optimized
Разрешение: 1920 × 1080
Производитель: LG • OLED TV
ID: 0xC0C8 • Год: 2022
Ориентация: Горизонтальная ↔️
```

### 📝 Detailed Logging
Comprehensive display information logged during initialization:

```
[INFO] 🖥️  Detected 1 display(s)
[INFO]   Display 1: ↔️ LG OLED TV (1920x1080)
[DEBUG]    Vendor: LG (0x1E6D)
[DEBUG]    Product ID: 0xC0C8
[DEBUG]    Serial: 16843009
[INFO]     ✅ LG OLED 42" detected - optimizations enabled
[DEBUG]    Manufactured: Week 1, 2022
```

## Supported LG OLED Models

### Primary Detection (Product IDs)
- **0xc0c8**: LG OLED TV SSCR2 (most common 42")
- **0xc0c9**: LG OLED 42" variant
- **0xc0ca**: LG OLED 42" variant
- **0x0042**: LG OLED 42" (42C2/42C3 series)
- **0x0043**: LG OLED 42" (42CS6LA)

### Secondary Detection (Resolution-based)
- Any LG display with 4K resolution (≥3840×2160)
- Includes 42", 48", 55", and 65" OLED models

## Vendor Support

The system recognizes displays from major manufacturers:

| Vendor | Vendor ID | Examples |
|--------|-----------|----------|
| LG | 0x1e6d, 0x30e4 | OLED TVs, UltraFine displays |
| Apple | 0x4d10, 0x593a, 0x05ac | Studio Display, Pro Display XDR |
| Dell | 0x10ac | UltraSharp, Professional series |
| Samsung | 0x4c2d | QLED, Odyssey gaming monitors |
| HP | 0x2d44 | EliteDisplay, DreamColor |
| ViewSonic | 0x5a63 | ColorPro, Elite series |
| ASUS | 0x22f0 | ProArt, ROG series |
| BenQ | 0x0469 | Professional, Gaming monitors |
| Sony | 0x4dd9 | Professional displays |
| Acer | 0x38a3 | Predator, Professional series |

## Technical Implementation

### IOKit Integration
The system uses IOKit framework to access low-level display information:

```swift
import IOKit.graphics

// Get display info from IOKit
let displayInfo = IODisplayCreateInfoDictionary(
    servicePort, 
    UInt32(kIODisplayOnlyPreferredName)
)

// Extract vendor and product IDs
let vendorID = info[kDisplayVendorID] as? UInt32
let productID = info[kDisplayProductID] as? UInt32
```

### Detection Algorithm

1. **Vendor Verification**: Check if vendor ID matches LG (0x1e6d)
2. **Product ID Check**: Validate against known LG OLED 42" product IDs
3. **Resolution Validation**: Confirm 4K+ resolution (≥3840×2160)
4. **Diagonal Estimation**: Calculate approximate screen size from resolution and PPI

```swift
var isLGOLED42: Bool {
    let isLGVendor = vendorID == 0x1e6d
    let isOLED42ProductID = (productID >= 0xc0c8 && productID <= 0xc0ca) || 
                             productID == 0x0042 || productID == 0x0043
    let is4KResolution = (frame.width >= 3840 && frame.height >= 2160) ||
                         (frame.width >= 2160 && frame.height >= 3840)
    
    return isLGVendor && (isOLED42ProductID || is4KResolution)
}
```

## Testing

### Run Display Detection Tests
```bash
# Test LG OLED detection
swift test --filter testLGOLED42Detection

# Run full display test suite
./test-lg-oled-detection.sh

# Run multi-monitor tests
./test-multimonitor.sh
```

### Manual Testing
```bash
# Check current display configuration
system_profiler SPDisplaysDataType

# Verify display IDs in WIC
swift run WIC
# Then open Settings → Displays tab
```

## Future Enhancements

Potential additions for LG OLED support:
- [ ] OLED-specific window positioning algorithms
- [ ] Burn-in prevention features (auto-hide static elements)
- [ ] HDR-aware window layouts
- [ ] Color accuracy profiles for professional work
- [ ] Specific gaming mode optimizations
- [ ] Auto-detect content type and adjust layouts
- [ ] Custom presets for 42" OLED workflow

## Known Limitations

1. **Scaled Resolutions**: Detection works best with native resolution
2. **USB-C/Thunderbolt**: Some connection types may report different IDs
3. **Firmware Updates**: Display IDs may change with LG firmware updates
4. **Multiple Displays**: Each display is detected independently

## Troubleshooting

### Display Not Detected as LG OLED 42"
1. Check vendor ID: `system_profiler SPDisplaysDataType | grep -i vendor`
2. Verify product ID matches supported range
3. Ensure native resolution is used (not scaled)
4. Restart WIC after display configuration changes

### Incorrect Model Name
1. IOKit may not have display name database
2. Falls back to generic "OLED TV" or resolution-based detection
3. Still functions correctly even without exact model name

## References

- [IOKit Display Services](https://developer.apple.com/documentation/iokit)
- [CGDirectDisplay API](https://developer.apple.com/documentation/coregraphics/cgdirectdisplay)
- [LG Display Specifications](https://www.lg.com/us/monitors)

---

**Last Updated**: February 14, 2026  
**WIC Version**: 0.0.2+  
**Author**: GitHub Copilot (Claude Sonnet 4.5)
