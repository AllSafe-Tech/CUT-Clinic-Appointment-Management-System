# One-time setup for Windows (PowerShell): generates Android files and installs packages.
if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
  Write-Host "Flutter is not installed or not on PATH. See https://docs.flutter.dev/get-started/install"
  exit 1
}
flutter create . --platforms=android --org za.ac.cut.clinic --project-name cut_clinic_app

# Release builds need the INTERNET permission (debug has it automatically).
$m = "android/app/src/main/AndroidManifest.xml"
$text = Get-Content $m -Raw
if ($text -notmatch "android.permission.INTERNET") {
  $text = $text -replace '(<manifest[^>]*>)', "`$1`n    <uses-permission android:name=`"android.permission.INTERNET`"/>"
  Set-Content $m $text
}

if (-not (Test-Path env.json)) { Copy-Item env.example.json env.json }
flutter pub get
Write-Host ""
Write-Host "Done. Edit env.json with your Supabase URL + anon key, then run:"
Write-Host "  flutter run --dart-define-from-file=env.json"
