# Отчёт об исправлении автоприклеивания

## Проблема
Функция автоприклеивания (snap to edge) не работала.

## Найденные причины
1. **Основная проблема**: В [WindowManager.swift](WIC/Managers/WindowManager.swift#L53) функция `setupMouseTracking()` была закомментирована, поэтому мониторинг движения мыши не запускался.

2. **Вторичная проблема**: Логика определения углов экрана работала неправильно. Сначала проверялись края, что приводило к тому, что углы не распознавались корректно.

## Исправления

### 1. Раскомментирован вызов setupMouseTracking() 
**Файл**: [WIC/Managers/WindowManager.swift](WIC/Managers/WindowManager.swift#L53)

```swift
// Было:
// setupMouseTracking()

// Стало:
setupMouseTracking()
```

### 2. Исправлена логика определения углов
**Файл**: [WIC/Managers/WindowManager.swift](WIC/Managers/WindowManager.swift#L196)

**Было**: Сначала проверялись края (левый, правый и т.д.), затем внутри них проверялись углы. Это приводило к тому, что при попадании в угол срабатывало определение края.

**Стало**: Сначала проверяются все края одновременно, затем определяются углы (комбинации двух краёв), и только потом отдельные края.

```swift
// Проверка углов - приоритетнее, чем края
let nearLeft = location.x - visibleFrame.minX < threshold
let nearRight = visibleFrame.maxX - location.x < threshold
let nearTop = visibleFrame.maxY - location.y < threshold
let nearBottom = location.y - visibleFrame.minY < threshold

// Углы (приоритет над краями)
if nearTop && nearLeft {
    targetPosition = .topLeftQuarter
} else if nearTop && nearRight {
    targetPosition = .topRightQuarter
} else if nearBottom && nearLeft {
    targetPosition = .bottomLeftQuarter
} else if nearBottom && nearRight {
    targetPosition = .bottomRightQuarter
}
// Края (только если не угол)
else if nearLeft {
    targetPosition = .leftHalf
} // и т.д.
```

## Созданные тесты

Создан новый файл тестов: [Tests/WICTests/SnapToEdgeTests.swift](Tests/WICTests/SnapToEdgeTests.swift)

### Покрытие тестами (14 тестов):
✅ `testSnapSettingsDefaults` - проверка настроек по умолчанию
✅ `testSnapThresholdRange` - проверка диапазона порога срабатывания
✅ `testLeftEdgeDetection` - определение левого края
✅ `testRightEdgeDetection` - определение правого края  
✅ `testTopEdgeDetection` - определение верхнего края
✅ `testBottomEdgeDetection` - определение нижнего края
✅ `testTopLeftCornerDetection` - определение верхнего левого угла
✅ `testTopRightCornerDetection` - определение верхнего правого угла
✅ `testBottomLeftCornerDetection` - определение нижнего левого угла
✅ `testBottomRightCornerDetection` - определение нижнего правого угла
✅ `testNoSnapInCenter` - отсутствие snap в центре экрана
✅ `testNoSnapJustOutsideThreshold` - отсутствие snap за пределами порога
✅ `testSnapOnSecondaryDisplay` - работа на втором мониторе
✅ `testSnapDetectionPerformance` - тест производительности (среднее время: 0.003s на 100 операций)

## Результаты тестирования

```
Test Suite 'SnapToEdgeTests' passed at 2026-01-16 10:33:40.630.
Executed 14 tests, with 0 failures (0 unexpected) in 0.378 seconds
```

**Все тесты успешно прошли!** ✅

## Как это работает

1. При перетаскивании окна мышью система отслеживает события `leftMouseDragged` и `leftMouseUp`
2. При отпускании кнопки мыши (`leftMouseUp`) проверяется позиция курсора
3. Если курсор находится в пределах порога (по умолчанию 20 пикселей) от края экрана, окно автоматически прикрепляется к этому краю
4. Углы определяются когда курсор близко одновременно к двум краям (например, вверху и слева)
5. Порог для углов = обычный порог (не умножается на 2, как было в старой логике)

## Настройки

Пользователь может настроить автоприклеивание в [Settings](WIC/Views/SettingsView.swift#L195):
- Включить/выключить функцию
- Порог срабатывания: 10-50 пикселей (по умолчанию 20)
- Отступ сетки: настраиваемый
- Длительность анимации: 0.2 секунды

## Статус
✅ **Исправлено и протестировано**

Автоприклеивание теперь работает корректно!
