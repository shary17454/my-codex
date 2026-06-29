$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

function Download-File {
  param(
    [Parameter(Mandatory = $true)][string]$Uri,
    [Parameter(Mandatory = $true)][string]$OutFile
  )

  try {
    Invoke-WebRequest -Uri $Uri -OutFile $OutFile -UseBasicParsing
  } catch {
    Write-Host "Invoke-WebRequest failed, retrying with curl.exe..."
    & curl.exe -L --retry 5 --retry-delay 3 -o $OutFile $Uri
    if ($LASTEXITCODE -ne 0) {
      throw "curl.exe failed to download $Uri"
    }
  }
}

$tempDir = Join-Path $env:TEMP "codex_flutter_install"
$flutterRoot = "C:\src"
$flutterDir = Join-Path $flutterRoot "flutter"
$gitInstaller = Join-Path $tempDir "Git-64-bit.exe"
$releasesJson = Join-Path $tempDir "flutter_releases_windows.json"

New-Item -ItemType Directory -Force -Path $tempDir | Out-Null
New-Item -ItemType Directory -Force -Path $flutterRoot | Out-Null

Write-Host "Checking Git..."
$gitCmd = Get-Command git -ErrorAction SilentlyContinue
if (-not $gitCmd) {
  Write-Host "Finding latest Git for Windows installer..."
  $gitLatestJson = Join-Path $tempDir "git_for_windows_latest.json"
  Download-File -Uri "https://api.github.com/repos/git-for-windows/git/releases/latest" -OutFile $gitLatestJson
  $gitLatest = Get-Content -LiteralPath $gitLatestJson -Raw | ConvertFrom-Json
  $gitAsset = $gitLatest.assets |
    Where-Object { $_.name -match "^Git-.*-64-bit\.exe$" } |
    Select-Object -First 1
  if (-not $gitAsset) {
    throw "Could not find Git for Windows 64-bit installer asset."
  }

  Write-Host "Downloading Git for Windows $($gitLatest.tag_name)..."
  Download-File -Uri $gitAsset.browser_download_url -OutFile $gitInstaller

  Write-Host "Installing Git for Windows..."
  Start-Process -FilePath $gitInstaller -ArgumentList "/VERYSILENT /NORESTART /NOCANCEL /SP-" -Wait
} else {
  Write-Host "Git already exists: $($gitCmd.Source)"
}

Write-Host "Downloading Flutter release manifest..."
Download-File -Uri "https://storage.googleapis.com/flutter_infra_release/releases/releases_windows.json" -OutFile $releasesJson
$manifest = Get-Content -LiteralPath $releasesJson -Raw | ConvertFrom-Json
$stableHash = $manifest.current_release.stable
$stableRelease = $manifest.releases | Where-Object { $_.hash -eq $stableHash } | Select-Object -First 1
if (-not $stableRelease) {
  throw "Could not find current stable Flutter release in manifest."
}

$archiveUrl = "https://storage.googleapis.com/flutter_infra_release/releases/$($stableRelease.archive)"
$flutterZip = Join-Path $tempDir (Split-Path $stableRelease.archive -Leaf)

if (Test-Path -LiteralPath $flutterDir) {
  Write-Host "Flutter folder already exists: $flutterDir"
} else {
  Write-Host "Downloading Flutter $($stableRelease.version)..."
  Download-File -Uri $archiveUrl -OutFile $flutterZip

  Write-Host "Extracting Flutter to $flutterRoot..."
  Expand-Archive -LiteralPath $flutterZip -DestinationPath $flutterRoot -Force
}

$pathsToAdd = @(
  "C:\Program Files\Git\cmd",
  "C:\src\flutter\bin"
)

$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
foreach ($path in $pathsToAdd) {
  if ($userPath -notlike "*$path*") {
    $userPath = "$userPath;$path"
  }
}
[Environment]::SetEnvironmentVariable("Path", $userPath, "User")

$env:Path = "$env:Path;C:\Program Files\Git\cmd;C:\src\flutter\bin"

Write-Host ""
Write-Host "Installed versions:"
& "C:\Program Files\Git\cmd\git.exe" --version
& "C:\src\flutter\bin\flutter.bat" --version

Write-Host ""
Write-Host "Running flutter doctor..."
& "C:\src\flutter\bin\flutter.bat" doctor
