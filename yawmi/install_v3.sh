#!/bin/bash
set -e

BASE=/workspaces/yawmi/yawmi
ZIP_DIR=/workspaces/yawmi/wirdi_v3

echo "=== Step 1: Unzip ==="
cd /workspaces/yawmi
unzip -o wirdi_v3.zip -d .
echo "Unzipped OK"

echo "=== Step 2: Copy files ==="
cp -v $ZIP_DIR/pubspec.yaml                      $BASE/pubspec.yaml
cp -v $ZIP_DIR/lib/screens/calendar_screen.dart  $BASE/lib/screens/calendar_screen.dart
cp -v $ZIP_DIR/lib/screens/settings_screen.dart  $BASE/lib/screens/settings_screen.dart
cp -v $ZIP_DIR/lib/providers/task_provider.dart  $BASE/lib/providers/task_provider.dart
cp -v $ZIP_DIR/lib/db/database_helper.dart       $BASE/lib/db/database_helper.dart
cp -v $ZIP_DIR/lib/widgets/day_cell.dart         $BASE/lib/widgets/day_cell.dart
cp -v $ZIP_DIR/lib/widgets/day_detail_sheet.dart $BASE/lib/widgets/day_detail_sheet.dart
cp -v $ZIP_DIR/lib/services/notification_service.dart $BASE/lib/services/notification_service.dart

echo "=== Step 3: Verify setArabicMode exists ==="
grep -n "setArabicMode" $BASE/lib/providers/task_provider.dart

echo "=== Step 4: flutter pub get ==="
cd $BASE
export PATH="$PATH:/home/codespace/flutter/bin"
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
export PATH=$JAVA_HOME/bin:$PATH
flutter pub get

echo "=== Step 5: Build APK ==="
flutter build apk --release --target-platform android-arm64
cp build/app/outputs/flutter-apk/app-release.apk /workspaces/yawmi/app-release.apk
echo "=== DONE: APK at /workspaces/yawmi/app-release.apk ==="
