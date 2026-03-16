# Wirdi v3.0 — Installation Instructions

## Files to replace in your Codespace

Run from: /workspaces/yawmi/yawmi/

### 1. pubspec.yaml (project root)
Replace your existing pubspec.yaml with the one in this zip.

### 2. lib/ files — copy each to its matching path:

| File in zip                              | Destination in project                          |
|------------------------------------------|-------------------------------------------------|
| lib/screens/calendar_screen.dart         | lib/screens/calendar_screen.dart                |
| lib/screens/settings_screen.dart         | lib/screens/settings_screen.dart                |
| lib/providers/task_provider.dart         | lib/providers/task_provider.dart                |
| lib/db/database_helper.dart              | lib/db/database_helper.dart                     |
| lib/widgets/day_cell.dart                | lib/widgets/day_cell.dart                       |
| lib/widgets/day_detail_sheet.dart        | lib/widgets/day_detail_sheet.dart               |
| lib/services/notification_service.dart   | lib/services/notification_service.dart          |

### 3. Build commands

export PATH="$PATH:/home/codespace/flutter/bin"
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
export PATH=$JAVA_HOME/bin:$PATH

flutter pub get
flutter build apk --release --target-platform android-arm64
cp build/app/outputs/flutter-apk/app-release.apk /workspaces/yawmi/app-release.apk

## New in v3.0

- Swipe left/right to navigate months (arrows removed)
- Long-press any day to quick-toggle done/not-done
- Smart notifications with Quran hadiths for empty days
- Monthly progress bar under week headers
- Streak counter 🔥 in AppBar
- Reminder time picker in Settings
- CSV export with share sheet (backup)
- Dark mode bug in edit sheet fixed
