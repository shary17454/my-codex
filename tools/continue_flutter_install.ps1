$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$tempDir = Join-Path $env:TEMP "codex_flutter_install"
$flutterRoot = "C:\src"
$flutterDir = Join-Path $flutterRoot "flutter"
$flutterZip = Join-Path $tempDir "flutter_windows_3.44.4-stable.full.zip"
$flutterUrl = "https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_3.44.4-stable.zip"

New-Item -ItemType Directory -Force -Path $tempDir | Out-Null
New-Item -ItemType Directory -Force -Path $flutterRoot | Out-Null

Write-Host "Completing Flutter download..."
if (Test-Path -LiteralPath $flutterZip) {
  $existingSize = (Get-Item -LiteralPath $flutterZip).Length
  if ($existingSize -lt 500MB) {
    Remove-Item -LiteralPath $flutterZip -Force
  }
}

try {
  Start-BitsTransfer -Source $flutterUrl -Destination $flutterZip -DisplayName "Flutter SDK" -Description "Downloading Flutter SDK for Windows"
} catch {
  Write-Host "BITS download failed, retrying with curl.exe..."
  & curl.exe -L --retry 10 --retry-delay 5 --output "$flutterZip" "$flutterUrl"
  if ($LASTEXITCODE -ne 0) {
    throw "Flutter download failed."
  }
}

$zipSize = (Get-Item -LiteralPath $flutterZip).Length
Write-Host "Downloaded zip size: $zipSize bytes"
if ($zipSize -lt 500MB) {
  throw "Downloaded Flutter zip looks incomplete."
}

if (Test-Path -LiteralPath $flutterDir) {
  Write-Host "Removing incomplete Flutter folder..."
  Remove-Item -LiteralPath $flutterDir -Recurse -Force
}

Write-Host "Extracting Flutter to $flutterRoot..."
Expand-Archive -LiteralPath $flutterZip -DestinationPath $flutterRoot -Force

$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
foreach ($path in @("C:\Program Files\Git\cmd", "C:\src\flutter\bin")) {
  if ($userPath -notlike "*$path*") {
    $userPath = "$userPath;$path"
  }
}
[Environment]::SetEnvironmentVariable("Path", $userPath, "User")

$env:Path = "$env:Path;C:\Program Files\Git\cmd;C:\src\flutter\bin"

Write-Host ""
Write-Host "Git:"
& "C:\Program Files\Git\cmd\git.exe" --version

Write-Host ""
Write-Host "Flutter:"
& "C:\src\flutter\bin\flutter.bat" --version

Write-Host ""
Write-Host "Flutter doctor:"
& "C:\src\flutter\bin\flutter.bat" doctor
