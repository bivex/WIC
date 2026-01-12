# WIC - Advanced Window Manager for macOS

<p align="center">
  <img src="https://img.shields.io/badge/platform-macOS-lightgrey.svg" alt="Platform">
  <img src="https://img.shields.io/badge/Swift-5.5+-orange.svg" alt="Swift">
  <img src="https://img.shields.io/badge/Apple%20Silicon-M4%20Optimized-blue.svg" alt="M4">
  <img src="https://img.shields.io/badge/license-MIT-green.svg" alt="License">
  <img src="https://img.shields.io/badge/productivity-window%20management-red.svg" alt="Productivity">
</p>

<p align="center">
  <strong>🚀 Smart Window Control | ⌨️ Hotkeys | 🎯 Automation | 📊 Performance Profiling</strong>
</p>

---

## 🔥 Key Features

**WIC** is a powerful native window manager for macOS, designed for maximum performance and convenience. The application provides complete control over window positioning using hotkeys, automatic layouts, and intelligent window management.

### 🎯 Core Capabilities

- **🖱️ Smart Window Positioning**: Quick placement of windows in half, third, or quarter of screen
- **🤖 Automatic Layouts**: 6 types of auto-layout for optimal window distribution
- **⌨️ Global Hotkeys**: 17+ customizable keyboard shortcuts
- **🖥️ Multi-Monitor Support**: Full support for multiple displays
- **🧲 Auto-Snap**: Intelligent screen edge detection
- **📊 Performance Profiling**: Detailed logging of all operations
- **🎨 Dark & Light Themes**: Adaptive interface matching system theme
- **💾 Settings Persistence**: Persistent settings and layouts

### 🤖 Auto-Layout System

WIC offers 6 unique window positioning algorithms:

| Layout | Description | Icon |
|--------|-------------|------|
| **Grid** | Even distribution of windows in a grid | `square.grid.2x2` |
| **Horizontal** | Windows arranged horizontally | `rectangle.split.3x1` |
| **Vertical** | Windows arranged vertically | `rectangle.split.1x3` |
| **Cascade** | Cascading window offset | `square.stack.3d.up` |
| **Fibonacci** | Distribution by golden ratio | `circle.grid.3x3` |
| **Focus** | Main window + sidebar | `rectangle.split.2x1` |

### ⌨️ Hotkeys

#### Screen Halves
- `⌘ ⌥ ←` - Left half of screen
- `⌘ ⌥ →` - Right half of screen
- `⌘ ⌥ ↑` - Top half of screen
- `⌘ ⌥ ↓` - Bottom half of screen

#### Screen Thirds
- `⌘ ⌥ D` - Left third
- `⌘ ⌥ F` - Center third
- `⌘ ⌥ G` - Right third
- `⌘ ⌥ E` - Left two thirds
- `⌘ ⌥ T` - Right two thirds

#### Screen Quarters
- `⌃ ⌘ ↑` - Top left quarter
- `⌃ ⌥ ⌘ U` - Top right quarter
- `⌃ ⌥ ⌘ J` - Bottom left quarter
- `⌃ ⌥ ⌘ K` - Bottom right quarter

#### Special Functions
- `⌘ ⌥ C` - Center window
- `⌘ ⌥ ↩` - Maximize window
- `⌘ ⌥ L` - Apply auto-layout (grid)
- `⌘ ⌥ ⇧ L` - Apply auto-layout (focus)

### 📊 Logging System

WIC includes an advanced logging system for performance profiling:

- **⏱️ Timestamps**: Precise measurement of operation execution time
- **📈 Profiling**: Automatic performance tracking
- **🔍 Log Levels**: Debug, Info, Warning, Error, Performance
- **📋 Detailed Reports**: Complete information about each operation

## 🚀 Quick Start

### System Requirements
- **macOS 12.0+**
- **Apple Silicon M4** (optimized) or Intel Mac
- **Swift 5.5+**

### Installation

#### From Source
```bash
# Clone repository
git clone https://github.com/bivex/WIC.git
cd WIC

# Build and run
swift run
```

#### Build for Release
```bash
# Build release version
swift build -c release

# Install to Applications
bash install.sh
```

### Permission Setup

1. **Go to System Settings** → **Privacy & Security** → **Accessibility**
2. **Add WIC** to the list of allowed applications
3. **Restart the application**

## 🎨 Interface and Settings

### Status Bar Menu
WIC works from the macOS status bar menu. Available features:
- ⚡ Quick actions (window positioning)
- ⚙️ Application settings
- 🚪 Quit application

### Application Settings

#### General Settings
- Launch at system startup
- Show icon in status bar
- Dark/light theme interface

#### Hotkeys
- Customize all keyboard combinations
- Restore default settings
- Check for key conflicts

#### Auto-Layout
- Choose default layout type
- Configure distribution parameters
- Preview layouts

#### Auto-Snap
- Configure trigger threshold (pixels)
- Enable/disable feature
- Exceptions for specific applications

#### Display Information
- List of connected monitors
- Resolutions and refresh rates
- Primary display

## 🏗️ Project Architecture

```
WIC/
├── WICApp.swift                      # Application entry point
├── Views/
│   ├── ContentView.swift             # Main user interface
│   ├── SettingsView.swift            # Settings window with tabs
│   └── AutoLayoutView.swift          # Auto-layout selection interface
├── Managers/
│   ├── WindowManager.swift           # Window management and layouts logic
│   └── HotkeyManager.swift           # Hotkey registration and handling
├── Helpers/
│   ├── AccessibilityHelper.swift     # Accessibility API interaction
│   └── Logger.swift                  # Logging and profiling system
├── Models/
│   └── WindowPosition.swift          # Position and settings models
└── Info.plist                        # Application configuration
```

## 🔧 Technologies

- **Swift 5.5+** - Modern Apple programming language
- **SwiftUI** - Declarative UI framework
- **AppKit** - Low-level window management API
- **Accessibility API** - Cross-application window management
- **Carbon Events** - Global system events
- **Combine** - Reactive programming
- **Swift Package Manager** - Dependency management

## ⚡ Performance Optimizations

### Apple Silicon M4
- **SIMD instructions** for high-performance computing
- **ARM64 optimization** compilation
- **Minimal resource consumption** CPU and memory
- **Response < 100ms** for hotkeys

### Logging System
- **Automatic profiling** of all operations
- **Bottleneck detection** in performance
- **Algorithm optimization** based on metrics
- **Memory usage monitoring**

## 📈 Profiling and Debugging

WIC includes a built-in profiling system for performance analysis:

```swift
// Example of logging system usage
let timer = Logger.shared.startOperation("Window Positioning")
// ... operation execution ...
timer.end() // Automatic execution time logging
```

Logs contain:
- Timestamps with millisecond precision
- Time delta between operations
- Detail level (Debug/Info/Warning/Error/Performance)
- File and function information

## 📖 Usage

### Quick Window Positioning
Use hotkeys to quickly position windows:
- `⌘ ⌥ ←` - Snap to left half
- `⌘ ⌥ →` - Snap to right half
- `⌘ ⌥ C` - Center window
- `⌘ ⌥ ↩` - Maximize window

### Auto-Layout
Apply automatic layouts to all visible windows:
1. Press `⌘ ⌥ L` for grid layout
2. Or open settings → Auto-Layout tab
3. Select desired layout type
4. Click "Apply Layout"

### Auto-Snap Feature
Intelligent window snapping to screen edges:
1. Drag window to screen edge
2. When cursor approaches edge (default 20 pixels), window auto-snaps
3. Drag to corner for quarter screen placement

### Settings

Open settings via status bar menu or press `⌘ ,`:
- **General**: Startup and display settings
- **Hotkeys**: Keyboard shortcut customization
- **Auto-Layout**: Automatic window arrangement without manual control
- **Auto-Snap**: Trigger threshold configuration
- **Displays**: Information about connected monitors
- **About**: Version information

## 🤝 Contributing

Pull requests are welcome! For major changes, please open an issue first to discuss.

### How to Contribute:
1. **Fork the repository**
2. **Create feature branch** (`git checkout -b feature/amazing-feature`)
3. **Commit changes** (`git commit -m 'Add amazing feature'`)
4. **Push to branch** (`git push origin feature/amazing-feature`)
5. **Create Pull Request**

### Code Requirements:
- Follow Swift code style
- Comment complex logic
- Tests for new features
- Update documentation

## 📝 License

Distributed under the MIT License. See [LICENSE](LICENSE) for details.

## 🙏 Acknowledgments

- **Inspiration**: Rectangle, Magnet, and other window managers
- **Technologies**: Apple's Accessibility API
- **Icons**: SF Symbols by Apple
- **Community**: For feedback and suggestions

## 📧 Contact and Support

- **🐛 Issues**: [GitHub Issues](https://github.com/bivex/WIC/issues)
- **💡 Feature Requests**: [GitHub Discussions](https://github.com/bivex/WIC/discussions)
- **📖 Documentation**: [Wiki](https://github.com/bivex/WIC/wiki)

---

<p align="center">
  <strong>Made with ❤️ for macOS | Optimized for Performance</strong>
</p>

<p align="center">
  <em>Boost your productivity with smart window management!</em>
</p>
