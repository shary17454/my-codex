$ErrorActionPreference = "Stop"

$project = "C:\Users\safwa\Documents\Codex\2026-06-19\new-chat\flutter_y60_catalog"
$log = Join-Path $project "flutter_web_server.log"
$err = Join-Path $project "flutter_web_server.err.log"

Remove-Item -LiteralPath $log -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath $err -Force -ErrorAction SilentlyContinue

$args = @(
  "run",
  "-d",
  "web-server",
  "--web-hostname",
  "127.0.0.1",
  "--web-port",
  "5005"
)

$process = Start-Process `
  -FilePath "C:\src\flutter\bin\flutter.bat" `
  -ArgumentList $args `
  -WorkingDirectory $project `
  -RedirectStandardOutput $log `
  -RedirectStandardError $err `
  -WindowStyle Hidden `
  -PassThru

Write-Host $process.Id

