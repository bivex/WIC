# WIC Logger Implementation

## Добавлен логгер с временными метками для профилирования

### Созданные файлы:

**Logger.swift** - Утилита для логирования с поддержкой:
- ⏱️ Временные метки (HH:mm:ss.SSS)
- 📊 Время с момента запуска (+X.XXXs)
- Δ Дельта между операциями ([ΔX.XXXms])
- 🎯 Уровни логирования (DEBUG, INFO, WARNING, ERROR, PERF)
- ⚡ Класс OperationTimer для замера времени выполнения

### Добавлено логирование в:

#### WICApp.swift
- ✅ Инициализация приложения с таймерами
- ✅ Настройка статус-бара
- ✅ Проверка Accessibility разрешений
- ✅ Все действия пользователя (snap, center, maximize)
- ✅ Все операции автолайаута

#### WindowManager.swift
- ✅ Инициализация с подсчетом дисплеев
- ✅ snapWindow() с логированием позиций и фреймов
- ✅ applyAutoLayout() с таймерами и подсчетом окон
- ✅ Каждый тип раскладки (grid, horizontal, vertical, etc.)

#### HotkeyManager.swift
- ✅ Инициализация с подсчетом горячих клавиш
- ✅ Регистрация hotkeys с успешным счетчиком
- ✅ Каждая регистрация hotkey

#### AccessibilityHelper.swift
- ✅ Проверка разрешений
- ✅ getAllWindows() с таймером и подсчетом окон
- ✅ Сканирование запущенных приложений

## Пример вывода логов:

```
[08:15:23.456] ℹ️ INFO [WICApp.swift:applicationDidFinishLaunching] [+0.000s] Application launching...
[08:15:23.457] ⏱️ PERF [WICApp.swift:applicationDidFinishLaunching] [+0.001s [Δ1.234ms]] Starting: Application Launch
[08:15:23.458] 🔍 DEBUG [WICApp.swift:applicationDidFinishLaunching] [+0.002s [Δ0.123ms]] Setting activation policy to accessory
[08:15:23.460] ⏱️ PERF [WICApp.swift:applicationDidFinishLaunching] [+0.004s [Δ2.345ms]] Starting: Status Bar Setup
[08:15:23.465] ⏱️ PERF [Logger.swift:end] [+0.009s [Δ5.678ms]] Completed: Status Bar Setup in 5.678ms
[08:15:23.466] ℹ️ INFO [WindowManager.swift:init] [+0.010s [Δ0.234ms]] Initializing WindowManager
[08:15:23.470] ℹ️ INFO [WindowManager.swift:init] [+0.014s [Δ4.567ms]] WindowManager initialized with 2 display(s)
[08:15:23.472] ℹ️ INFO [HotkeyManager.swift:init] [+0.016s [Δ2.345ms]] Initializing HotkeyManager
[08:15:23.485] ℹ️ INFO [HotkeyManager.swift:init] [+0.029s [Δ13.456ms]] HotkeyManager initialized with 17 hotkey(s)
[08:15:23.486] ⏱️ PERF [Logger.swift:end] [+0.030s [Δ0.567ms]] Completed: Application Launch in 30.123ms
[08:15:23.487] ℹ️ INFO [WICApp.swift:applicationDidFinishLaunching] [+0.031s [Δ0.123ms]] Application launch complete

// При действии пользователя:
[08:16:45.123] ℹ️ INFO [WICApp.swift:applyGridLayout] [+82.123s [Δ0.234ms]] User action: Apply grid layout
[08:16:45.124] ℹ️ INFO [WindowManager.swift:applyAutoLayout] [+82.124s [Δ1.234ms]] Applying auto-layout: Сетка
[08:16:45.125] ⏱️ PERF [WindowManager.swift:applyAutoLayout] [+82.125s [Δ0.567ms]] Starting: Auto Layout - Сетка
[08:16:45.126] 🔍 DEBUG [AccessibilityHelper.swift:getAllWindows] [+82.126s [Δ1.234ms]] Getting all windows...
[08:16:45.135] 🔍 DEBUG [AccessibilityHelper.swift:getAllWindows] [+82.135s [Δ9.123ms]] Found 4 window(s)
[08:16:45.136] 🔍 DEBUG [WindowManager.swift:applyGridLayout] [+82.136s [Δ0.234ms]] Applying grid layout to 4 windows
[08:16:45.137] 🔍 DEBUG [WindowManager.swift:applyGridLayout] [+82.137s [Δ1.234ms]] Grid: 2x2
[08:16:45.156] ⏱️ PERF [Logger.swift:end] [+82.156s [Δ19.456ms]] Completed: Auto Layout - Сетка in 31.234ms
[08:16:45.157] ℹ️ INFO [WindowManager.swift:applyAutoLayout] [+82.157s [Δ0.234ms]] Auto-layout applied successfully
```

## Использование:

1. **Запуск с логированием:**
   ```bash
   swift run
   ```

2. **Фильтрация логов по уровню:**
   ```bash
   swift run 2>&1 | grep "PERF"     # Только производительность
   swift run 2>&1 | grep "ERROR"   # Только ошибки
   ```

3. **Сохранение логов в файл:**
   ```bash
   swift run 2>&1 | tee wic-logs.txt
   ```

## Анализ производительности:

Логи показывают:
- Время запуска приложения
- Время инициализации каждого компонента
- Время выполнения каждой операции
- Количество окон и дисплеев
- Дельту между операциями для выявления узких мест

## Сборка:

```bash
chmod +x build-with-logger.sh
./build-with-logger.sh
```

Или напрямую:
```bash
swift build
swift run
```
