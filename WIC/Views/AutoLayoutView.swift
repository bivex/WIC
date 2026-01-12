//
//  AutoLayoutView.swift
//  WIC
//
//  Настройки автоматической раскладки окон
//

import SwiftUI

struct AutoLayoutView: View {
    @EnvironmentObject var windowManager: WindowManager
    @State private var selectedLayout: AutoLayoutType = .grid
    @State private var windowCount: Int = 0
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Автоматическая раскладка")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Автоматически расставьте все видимые окна на экране")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                
                Divider()
                
                // Выбор типа раскладки
                VStack(alignment: .leading, spacing: 12) {
                    Text("Выберите тип раскладки:")
                        .font(.headline)

                    // Группировка по категориям
                    VStack(alignment: .leading, spacing: 20) {
                        // Умные режимы
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "brain.head.profile")
                                    .foregroundColor(.purple)
                                Text("Умные режимы")
                                    .font(.headline)
                                    .foregroundColor(.purple)
                            }
                            .padding(.bottom, 4)

                            ForEach(AutoLayoutType.allCases.filter { $0.category == "Умные режимы" }) { layoutType in
                                AutoLayoutOptionCard(
                                    layoutType: layoutType,
                                    isSelected: selectedLayout == layoutType,
                                    action: {
                                        selectedLayout = layoutType
                                    }
                                )
                            }
                        }

                        Divider()

                        // Premium Work Modes
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "star.fill")
                                    .foregroundColor(.yellow)
                                Text("Premium Work Modes")
                                    .font(.headline)
                                    .foregroundColor(.orange)
                            }
                            .padding(.bottom, 4)

                            ForEach(AutoLayoutType.allCases.filter { $0.category == "Premium Work Modes" }) { layoutType in
                                AutoLayoutOptionCard(
                                    layoutType: layoutType,
                                    isSelected: selectedLayout == layoutType,
                                    action: {
                                        selectedLayout = layoutType
                                    }
                                )
                            }
                        }

                        Divider()

                        // Базовые режимы
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "square.grid.2x2")
                                    .foregroundColor(.gray)
                                Text("Базовые режимы")
                                    .font(.headline)
                                    .foregroundColor(.gray)
                            }
                            .padding(.bottom, 4)

                            ForEach(AutoLayoutType.allCases.filter { $0.category == "Базовые" }) { layoutType in
                                AutoLayoutOptionCard(
                                    layoutType: layoutType,
                                    isSelected: selectedLayout == layoutType,
                                    action: {
                                        selectedLayout = layoutType
                                    }
                                )
                            }
                        }
                        
                        Divider()

                        // Академические алгоритмы
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "atom")
                                    .foregroundColor(.orange)
                                Text("Academic Algorithms")
                                    .font(.headline)
                                    .foregroundColor(.orange)
                            }
                            .padding(.bottom, 4)

                            ForEach(AutoLayoutType.allCases.filter { $0.category == "Academic Algorithms" }) { layoutType in
                                AutoLayoutOptionCard(
                                    layoutType: layoutType,
                                    isSelected: selectedLayout == layoutType,
                                    action: {
                                        selectedLayout = layoutType
                                    }
                                )
                            }
                        }
                        
                        Divider()

                        // Premium Programming Modes
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "chevron.left.forwardslash.chevron.right")
                                    .foregroundColor(.blue)
                                Text("Premium Programming Modes")
                                    .font(.headline)
                                    .foregroundColor(.blue)
                            }
                            .padding(.bottom, 4)

                            ForEach(AutoLayoutType.allCases.filter { $0.category == "Premium Programming Modes" }) { layoutType in
                                AutoLayoutOptionCard(
                                    layoutType: layoutType,
                                    isSelected: selectedLayout == layoutType,
                                    action: {
                                        selectedLayout = layoutType
                                    }
                                )
                            }
                        }
                    }
                }
                
                    Divider()
                
                // Предпросмотр и действия
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "macwindow.on.rectangle")
                            .font(.title2)
                            .foregroundColor(.blue)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Найдено окон: \(windowCount)")
                                .font(.headline)
                            Text("Будут организованы в формате: \(selectedLayout.displayName)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        
                        Spacer()
                        
                        Button("Обновить") {
                            updateWindowCount()
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding()
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(10)
                    
                    HStack(spacing: 12) {
                        Button(action: {
                            windowManager.applyAutoLayout(selectedLayout)
                        }) {
                            Label("Применить раскладку", systemImage: "sparkles")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(windowCount == 0)
                        
                        Button(action: {
                            windowManager.resetAllWindows()
                        }) {
                            Label("Сбросить", systemImage: "arrow.counterclockwise")
                        }
                        .buttonStyle(.bordered)
                    }
                }
                
                Divider()
                
                // Подсказки
                VStack(alignment: .leading, spacing: 8) {
                    Text("💡 Подсказки")
                        .font(.headline)
                    
                    HelpRow(icon: "keyboard", text: "Используйте ⌘⌥L для быстрого вызова автолайаута")
                    HelpRow(icon: "arrow.up.left.and.arrow.down.right", text: "Раскладка применяется ко всем видимым окнам на активном мониторе")
                    HelpRow(icon: "display.2", text: "Для множественных мониторов раскладка применяется к каждому отдельно")
                    
                    // Подсказки для академических алгоритмов
                    if selectedLayout.category == "Academic Algorithms" {
                        Divider()
                        HelpRow(icon: "atom", text: "Academic алгоритмы основаны на научных исследованиях UI-раскладок")
                        HelpRow(icon: "arrow.triangle.2.circlepath", text: "Kaczmarz: Итеративные проекции, сходимость за O(n·m)")
                        HelpRow(icon: "scope", text: "Interior Point: Квадратичная оптимизация с барьерами")
                        HelpRow(icon: "square.on.square.dashed", text: "Active Set: QP-решатель для активных ограничений")
                        HelpRow(icon: "waveform.path", text: "Linear Relaxation: Метод Гаусса-Зейделя с релаксацией")
                        HelpRow(icon: "triangle", text: "Constraint Simplex: LP-оптимизация по вершинам")
                    }
                }
                .padding()
                .background(Color.blue.opacity(0.05))
                .cornerRadius(10)
            }
            .padding()
        }
        .onAppear {
            updateWindowCount()
        }
    }
    
    private func updateWindowCount() {
        windowCount = windowManager.getVisibleWindowsCount()
    }
}

struct AutoLayoutOptionCard: View {
    let layoutType: AutoLayoutType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 15) {
                Image(systemName: layoutType.iconName)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : .blue)
                    .frame(width: 40)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(layoutType.displayName)
                        .font(.headline)
                        .foregroundColor(isSelected ? .white : .primary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Text(layoutType.description)
                        .font(.caption)
                        .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.white)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(isSelected ? Color.blue : Color.secondary.opacity(0.1))
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
    }
}

struct HelpRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 20)
            
            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

#Preview {
    AutoLayoutView()
        .environmentObject(WindowManager.shared)
        .frame(width: 600, height: 700)
}
