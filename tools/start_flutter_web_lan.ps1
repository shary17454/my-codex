$ErrorActionPreference = "Stop"

$project = "C:\Users\safwa\Documents\Codex\2026-06-19\new-chat\flutter_y60_catalog"
$log = Join-Path $project "flutter_web_server_lan.log"
$err = Join-Path $project "flutter_web_server_lan.err.log"

Get-Process | Where-Object {
  $_.ProcessName -like "*dart*" -or $_.ProcessName -like "*flutter*"
} | Stop-Process -Force -ErrorAction SilentlyContinue

Remove-Item -LiteralPath $log -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath $err -Force -ErrorAction SilentlyContinue

$args = @(
  "run",
  "-d",
  "web-server",
  "--release",
  "--web-hostname",
  "0.0.0.0",
  "--web-port",
  "5005"
)

Start-Process `
  -FilePath "C:\src\flutter\bin\flutter.bat" `
  -ArgumentList $args `
  -WorkingDirectory $project `
  -RedirectStandardOutput $log `
  -RedirectStandardError $err `
  -WindowStyle Hidden

Start-Sleep -Seconds 8

Get-NetIPAddress -AddressFamily IPv4 |
  Where-Object {
    $_.IPAddress -notlike "127.*" -and
    $_.IPAddress -notlike "169.254.*" -and
    $_.PrefixOrigin -ne "WellKnown"
  } |
  Select-Object InterfaceAlias,IPAddress
