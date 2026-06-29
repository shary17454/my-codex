$ErrorActionPreference = "Stop"

$root = "C:\Users\safwa\Documents\Codex\2026-06-19\new-chat"
$project = Join-Path $root "flutter_y60_catalog"
$webRoot = Join-Path $project "build\web"
$log = Join-Path $project "static_web_server.log"
$err = Join-Path $project "static_web_server.err.log"

Get-Process | Where-Object {
  $_.ProcessName -like "*dart*" -or $_.ProcessName -like "*flutter*"
} | Stop-Process -Force -ErrorAction SilentlyContinue

Push-Location $project
& "C:\src\flutter\bin\flutter.bat" build web --release -O4 --no-source-maps --no-web-resources-cdn
Pop-Location

Remove-Item -LiteralPath $log -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath $err -Force -ErrorAction SilentlyContinue

Start-Process `
  -FilePath "C:\src\flutter\bin\cache\dart-sdk\bin\dart.exe" `
  -ArgumentList @((Join-Path $root "tools\static_file_server.dart"), $webRoot, "5005") `
  -WorkingDirectory $root `
  -RedirectStandardOutput $log `
  -RedirectStandardError $err `
  -WindowStyle Hidden

Start-Sleep -Seconds 2
ipconfig | Select-String -Pattern "IPv4 Address"
