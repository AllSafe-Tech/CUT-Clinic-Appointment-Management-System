#!/usr/bin/env bash
# One-time setup: generates the Android platform files and installs packages.
set -e
if ! command -v flutter >/dev/null 2>&1; then
  echo "Flutter is not installed or not on PATH. See https://docs.flutter.dev/get-started/install"
  exit 1
fi
flutter create . --platforms=android --org za.ac.cut.clinic --project-name cut_clinic_app

# Release builds need the INTERNET permission (debug has it automatically).
M=android/app/src/main/AndroidManifest.xml
if ! grep -q "android.permission.INTERNET" "$M"; then
  sed -i.bak 's#<manifest\([^>]*\)>#<manifest\1>\n    <uses-permission android:name="android.permission.INTERNET"/>#' "$M" && rm -f "$M.bak"
fi

[ -f env.json ] || cp env.example.json env.json
flutter pub get
echo
echo "Done. Edit env.json with your Supabase URL + anon key, then run:"
echo "  flutter run --dart-define-from-file=env.json"
