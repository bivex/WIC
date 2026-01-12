//
//  ContentView.swift
//  WIC
//
//  Основной UI компонент (не используется, приложение работает из статус-бара)
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var windowManager: WindowManager
    @EnvironmentObject var hotkeyManager: HotkeyManager
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "rectangle.split.3x3")
                .resizable()
                .frame(width: 100, height: 100)
                .foregroundColor(.accentColor)
            
            Text("WIC")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Window Manager для macOS")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Divider()
                .padding(.vertical)
            
            VStack(alignment: .leading, spacing: 10) {
                Text("Приложение работает из статус-бара")
                    .font(.headline)
                
                Text("Используйте горячие клавиши для управления окнами")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("Или кликните на иконку WIC в статус-баре для доступа к меню")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(10)
            
            Button("Открыть настройки") {
                NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(40)
        .frame(width: 400, height: 500)
    }
}

#Preview {
    ContentView()
        .environmentObject(WindowManager.shared)
        .environmentObject(HotkeyManager.shared)
}
