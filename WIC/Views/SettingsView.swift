//
//  SettingsView.swift
//  WIC
//
//  Окно настроек приложения
//

import SwiftUI
import Carbon

struct SettingsView: View {
    @EnvironmentObject var windowManager: WindowManager
    @EnvironmentObject var hotkeyManager: HotkeyManager
    @State private var selectedTab: SettingsTab = .general
    
    enum SettingsTab: String, CaseIterable {
        case general = "Основные"
        case hotkeys = "Горячие клавиши"
        case autoLayout = "Автолайаут"
        case snap = "Автоматическое прикрепление"
        case displays = "Дисплеи"
        case about = "О программе"
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            GeneralSettingsView()
                .tabItem {
                    Label("Основные", systemImage: "gear")
                }
                .tag(SettingsTab.general)
            
            HotkeysSettingsView()
                .tabItem {
                    Label("Горячие клавиши", systemImage: "keyboard")
                }
                .tag(SettingsTab.hotkeys)
            
            AutoLayoutView()
                .tabItem {
                    Label("Автолайаут", systemImage: "square.grid.2x2")
                }
                .tag(SettingsTab.autoLayout)
            
            SnapSettingsView()
                .tabItem {
                    Label("Автоприкрепление", systemImage: "magnet")
                }
                .tag(SettingsTab.snap)
            
            DisplaysSettingsView()
                .tabItem {
                    Label("Дисплеи", systemImage: "display.2")
                }
                .tag(SettingsTab.displays)
            
            AboutSettingsView()
                .tabItem {
                    Label("О программе", systemImage: "info.circle")
                }
                .tag(SettingsTab.about)
        }
        .frame(minWidth: 600, minHeight: 500)
    }
}

// MARK: - General Settings

struct GeneralSettingsView: View {
    @AppStorage("launchAtLogin") private var launchAtLogin = false
    @AppStorage("showMenuBarIcon") private var showMenuBarIcon = true
    
    var body: some View {
        Form {
            Section {
                Toggle("Запускать при входе в систему", isOn: $launchAtLogin)
                Toggle("Показывать иконку в статус-баре", isOn: $showMenuBarIcon)
            } header: {
                Text("Запуск")
            }
            
            Section {
                HStack {
                    Text("Версия:")
                    Spacer()
                    Text("1.0.0")
                        .foregroundColor(.secondary)
                }
            } header: {
                Text("Информация")
            }
        }
        .padding()
    }
}

// MARK: - Hotkeys Settings

struct HotkeysSettingsView: View {
    @EnvironmentObject var hotkeyManager: HotkeyManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Настройка горячих клавиш")
                .font(.headline)
                .padding(.bottom, 5)
            
            Text("Нажмите на комбинацию клавиш, чтобы изменить её")
                .font(.caption)
                .foregroundColor(.secondary)
            
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(hotkeyManager.hotkeys) { hotkey in
                        HotkeyRow(hotkey: hotkey)
                    }
                }
                .padding()
            }
        }
        .padding()
    }
}

struct HotkeyRow: View {
    let hotkey: HotkeyBinding
    @State private var isEditing = false
    
    var body: some View {
        HStack {
            Toggle("", isOn: .constant(hotkey.isEnabled))
                .labelsHidden()
                .toggleStyle(.switch)
            
            Text(hotkey.name)
                .frame(minWidth: 150, alignment: .leading)
            
            Spacer()
            
            HStack(spacing: 4) {
                Text(hotkey.modifiers.displayString)
                    .font(.system(.body, design: .monospaced))
                Text(keyCodeToString(hotkey.keyCode))
                    .font(.system(.body, design: .monospaced))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(6)
            
            Button(action: {
                isEditing.toggle()
            }) {
                Image(systemName: "pencil")
            }
            .buttonStyle(.borderless)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color.secondary.opacity(0.05))
        .cornerRadius(8)
    }
    
    private func keyCodeToString(_ keyCode: UInt16) -> String {
        // Упрощенная конвертация key code в строку
        let keyMap: [UInt16: String] = [
            UInt16(kVK_LeftArrow): "←",
            UInt16(kVK_RightArrow): "→",
            UInt16(kVK_UpArrow): "↑",
            UInt16(kVK_DownArrow): "↓",
            UInt16(kVK_Return): "↩",
            UInt16(kVK_ANSI_C): "C",
            UInt16(kVK_ANSI_D): "D",
            UInt16(kVK_ANSI_E): "E",
            UInt16(kVK_ANSI_F): "F",
            UInt16(kVK_ANSI_G): "G",
            UInt16(kVK_ANSI_T): "T",
            UInt16(kVK_ANSI_U): "U",
            UInt16(kVK_ANSI_J): "J",
            UInt16(kVK_ANSI_K): "K",
        ]
        return keyMap[keyCode] ?? "?"
    }
}

// MARK: - Snap Settings

struct SnapSettingsView: View {
    @EnvironmentObject var windowManager: WindowManager
    @State private var snapEnabled = true
    @State private var snapThreshold: Double = 20
    @State private var gridPadding: Double = 10
    
    var body: some View {
        Form {
            Section {
                Toggle("Включить автоматическое прикрепление", isOn: $snapEnabled)
                    .onChange(of: snapEnabled) { newValue in
                        windowManager.snapSettings.isEnabled = newValue
                    }
            } header: {
                Text("Автоматическое прикрепление")
            }
            
            if snapEnabled {
                Section {
                    VStack(alignment: .leading) {
                        Text("Порог срабатывания: \(Int(snapThreshold)) пикселей")
                        Slider(value: $snapThreshold, in: 10...50, step: 5)
                            .onChange(of: snapThreshold) { newValue in
                                windowManager.snapSettings.snapThreshold = newValue
                            }
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Отступ сетки от краёв: \(Int(gridPadding)) пикселей")
                        Slider(value: $gridPadding, in: 5...30, step: 5)
                            .onChange(of: gridPadding) { newValue in
                                windowManager.snapSettings.gridPadding = newValue
                            }
                    }
                    
                    Text("При перетаскивании окна к краю экрана на расстояние меньше указанного порога, окно автоматически прикрепится к краю.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } header: {
                    Text("Настройки")
                }
            }
            
            Section {
                HStack {
                    Image(systemName: "hand.point.up")
                        .foregroundColor(.blue)
                    Text("Перетащите окно к краю экрана, чтобы автоматически изменить его размер")
                        .font(.caption)
                }
                
                HStack {
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                        .foregroundColor(.green)
                    Text("Перетащите к углу экрана для размещения в четверти экрана")
                        .font(.caption)
                }
            } header: {
                Text("Подсказки")
            }
        }
        .padding()
        .onAppear {
            snapEnabled = windowManager.snapSettings.isEnabled
            snapThreshold = windowManager.snapSettings.snapThreshold
            gridPadding = windowManager.snapSettings.gridPadding
        }
    }
}

// MARK: - Displays Settings

struct DisplaysSettingsView: View {
    @EnvironmentObject var windowManager: WindowManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Подключенные дисплеи")
                .font(.headline)
            
            if windowManager.currentDisplays.isEmpty {
                Text("Дисплеи не обнаружены")
                    .foregroundColor(.secondary)
            } else {
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(windowManager.currentDisplays) { display in
                            DisplayRow(display: display)
                        }
                    }
                }
            }
            
            Spacer()
            
            Button("Обновить список дисплеев") {
                windowManager.objectWillChange.send()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

struct DisplayRow: View {
    let display: DisplayInfo
    
    var body: some View {
        HStack {
            Image(systemName: display.isVertical ? "rectangle.portrait" : "rectangle")
                .font(.largeTitle)
                .foregroundColor(.blue)
                .frame(width: 60)
            
            VStack(alignment: .leading, spacing: 5) {
                Text(display.name)
                    .font(.headline)
                
                Text("Разрешение: \(Int(display.frame.width)) × \(Int(display.frame.height))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("Ориентация: \(display.isVertical ? "Вертикальная" : "Горизонтальная")")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color.secondary.opacity(0.05))
        .cornerRadius(10)
    }
}

// MARK: - About Settings

struct AboutSettingsView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "rectangle.split.3x3")
                .resizable()
                .frame(width: 80, height: 80)
                .foregroundColor(.accentColor)
            
            Text("WIC")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Window Manager для macOS")
                .font(.title3)
                .foregroundColor(.secondary)
            
            Text("Версия 1.0.0")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Divider()
                .padding(.vertical)
            
            VStack(spacing: 10) {
                Text("Нативное приложение для управления окнами")
                    .font(.body)
                
                Text("Оптимизировано для Apple Silicon M4")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            HStack(spacing: 15) {
                Button("GitHub") {
                    if let url = URL(string: "https://github.com/bivex/WIC") {
                        NSWorkspace.shared.open(url)
                    }
                }
                .buttonStyle(.bordered)
                
                Button("Документация") {
                    if let url = URL(string: "https://github.com/bivex/WIC/blob/main/README.md") {
                        NSWorkspace.shared.open(url)
                    }
                }
                .buttonStyle(.bordered)
            }
            
            Text("© 2026 WIC. Все права защищены.")
                .font(.caption2)
                .foregroundColor(.secondary)
                .padding(.top)
        }
        .padding(40)
    }
}

#Preview {
    SettingsView()
        .environmentObject(WindowManager.shared)
        .environmentObject(HotkeyManager.shared)
}
