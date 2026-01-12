#!/bin/bash

# Скрипт установки WIC

set -e

echo "🔨 Сборка WIC в релизном режиме..."
swift build -c release

echo "📦 Создание .app bundle..."

APP_DIR="/Applications/WIC.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

# Удалить старую версию если есть
if [ -d "$APP_DIR" ]; then
    echo "🗑️  Удаление старой версии..."
    rm -rf "$APP_DIR"
fi

# Создать структуру .app
echo "📁 Создание структуры приложения..."
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"

# Копировать исполняемый файл
echo "📋 Копирование исполняемого файла..."
cp .build/release/WIC "$MACOS_DIR/"

# Копировать Info.plist
echo "📋 Копирование Info.plist..."
# Заменить переменные в Info.plist
sed -e 's/\$(EXECUTABLE_NAME)/WIC/g' \
    -e 's/\$(PRODUCT_NAME)/WIC/g' \
    -e 's/\$(PRODUCT_BUNDLE_IDENTIFIER)/com.wic.app/g' \
    -e 's/\$(DEVELOPMENT_LANGUAGE)/en/g' \
    -e 's/\$(PRODUCT_BUNDLE_PACKAGE_TYPE)/APPL/g' \
    -e 's/\$(MACOSX_DEPLOYMENT_TARGET)/13.0/g' \
    WIC/Info.plist > "$CONTENTS_DIR/Info.plist"

# Создать иконку (опционально - можно создать позже)
# echo "🎨 Создание иконки..."
# if [ -f "Assets/AppIcon.icns" ]; then
#     cp Assets/AppIcon.icns "$RESOURCES_DIR/"
# fi

echo "✅ WIC установлен в /Applications/"
echo ""
echo "🚀 Добавление в автозагрузку..."

# Добавить в Login Items через osascript
osascript <<EOF
tell application "System Events"
    make login item at end with properties {path:"/Applications/WIC.app", hidden:false}
end tell
EOF

echo "✅ WIC добавлен в автозагрузку"
echo ""
echo "🎉 Установка завершена!"
echo ""
echo "Запустите WIC из /Applications или он запустится автоматически при следующем входе в систему."
