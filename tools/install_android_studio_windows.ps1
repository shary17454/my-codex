$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

function Download-File {
  param(
    [Parameter(Mandatory = $true)][string]$Uri,
    [Parameter(Mandatory = $true)][string]$OutFile
  )

  try {
    Start-BitsTransfer -Source $Uri -Destination $OutFile -DisplayName (Split-Path $OutFile -Leaf)
  } catch {
    Write-Host "BITS download failed, retrying with curl.exe..."
    & curl.exe -L --retry 10 --retry-delay 5 --output "$OutFile" "$Uri"
    if ($LASTEXITCODE -ne 0) {
      throw "Download failed: $Uri"
    }
  }
}

$tempDir = Join-Path $env:TEMP "codex_android_install"
$studioInstaller = Join-Path $tempDir "android-studio-quail1-patch2-windows.exe"
$cmdlineZip = Join-Path $tempDir "commandlinetools-win-14742923_latest.zip"
$cmdlineExtract = Join-Path $tempDir "cmdline_extract"
$sdkRoot = Join-Path $env:LOCALAPPDATA "Android\Sdk"
$sdkCmdlineLatest = Join-Path $sdkRoot "cmdline-tools\latest"
$androidStudioJbr = "C:\Program Files\Android\Android Studio\jbr"

$studioUrl = "https://edgedl.me.gvt1.com/android/studio/install/2026.1.1.10/android-studio-quail1-patch2-windows.exe"
$studioSha256 = "7c515f28619d90938bacef9562625719a5c1a206a01b8eaab99d9228c53330a0"
$cmdlineUrl = "https://dl.google.com/android/repository/commandlinetools-win-14742923_latest.zip"

New-Item -ItemType Directory -Force -Path $tempDir | Out-Null
New-Item -ItemType Directory -Force -Path $sdkRoot | Out-Null

if (-not (Test-Path -LiteralPath "C:\Program Files\Android\Android Studio\bin\studio64.exe")) {
  Write-Host "Downloading Android Studio..."
  if (-not (Test-Path -LiteralPath $studioInstaller) -or ((Get-Item -LiteralPath $studioInstaller).Length -lt 1GB)) {
    if (Test-Path -LiteralPath $studioInstaller) {
      Remove-Item -LiteralPath $studioInstaller -Force
    }
    Download-File -Uri $studioUrl -OutFile $studioInstaller
  }

  $hash = (Get-FileHash -LiteralPath $studioInstaller -Algorithm SHA256).Hash.ToLowerInvariant()
  if ($hash -ne $studioSha256) {
    throw "Android Studio installer checksum mismatch. Expected $studioSha256 but got $hash."
  }

  Write-Host "Installing Android Studio..."
  Start-Process -FilePath $studioInstaller -ArgumentList "/S" -Wait
} else {
  Write-Host "Android Studio already installed."
}

Write-Host "Installing Android SDK command-line tools..."
if (-not (Test-Path -LiteralPath (Join-Path $sdkCmdlineLatest "bin\sdkmanager.bat"))) {
  if (-not (Test-Path -LiteralPath $cmdlineZip) -or ((Get-Item -LiteralPath $cmdlineZip).Length -lt 100MB)) {
    if (Test-Path -LiteralPath $cmdlineZip) {
      Remove-Item -LiteralPath $cmdlineZip -Force
    }
    Download-File -Uri $cmdlineUrl -OutFile $cmdlineZip
  }

  if (Test-Path -LiteralPath $cmdlineExtract) {
    Remove-Item -LiteralPath $cmdlineExtract -Recurse -Force
  }
  New-Item -ItemType Directory -Force -Path $cmdlineExtract | Out-Null
  Expand-Archive -LiteralPath $cmdlineZip -DestinationPath $cmdlineExtract -Force

  New-Item -ItemType Directory -Force -Path (Split-Path $sdkCmdlineLatest -Parent) | Out-Null
  if (Test-Path -LiteralPath $sdkCmdlineLatest) {
    Remove-Item -LiteralPath $sdkCmdlineLatest -Recurse -Force
  }
  New-Item -ItemType Directory -Force -Path $sdkCmdlineLatest | Out-Null
  Copy-Item -Path (Join-Path $cmdlineExtract "cmdline-tools\*") -Destination $sdkCmdlineLatest -Recurse -Force
}

$sdkManager = Join-Path $sdkCmdlineLatest "bin\sdkmanager.bat"
Write-Host "Installing Android SDK packages..."
if (Test-Path -LiteralPath (Join-Path $androidStudioJbr "bin\java.exe")) {
  $env:JAVA_HOME = $androidStudioJbr
  $env:Path = "$androidStudioJbr\bin;$env:Path"
}
& $sdkManager --sdk_root=$sdkRoot "platform-tools" "platforms;android-36" "build-tools;36.0.0" "emulator"
if ($LASTEXITCODE -ne 0) {
  throw "sdkmanager package install failed."
}

Write-Host "Accepting Android SDK licenses..."
$yesAnswers = ("y`r`n" * 80)
$psi = New-Object System.Diagnostics.ProcessStartInfo
$psi.FileName = $sdkManager
$psi.Arguments = "--sdk_root=`"$sdkRoot`" --licenses"
$psi.RedirectStandardInput = $true
$psi.RedirectStandardOutput = $true
$psi.RedirectStandardError = $true
$psi.UseShellExecute = $false
$process = [System.Diagnostics.Process]::Start($psi)
$process.StandardInput.Write($yesAnswers)
$process.StandardInput.Close()
$stdout = $process.StandardOutput.ReadToEnd()
$stderr = $process.StandardError.ReadToEnd()
$process.WaitForExit()
Write-Host $stdout
if ($process.ExitCode -ne 0) {
  Write-Host $stderr
  throw "Accepting SDK licenses failed."
}

$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
$pathsToAdd = @(
  (Join-Path $sdkRoot "platform-tools"),
  (Join-Path $sdkRoot "cmdline-tools\latest\bin")
)
foreach ($path in $pathsToAdd) {
  if ($userPath -notlike "*$path*") {
    $userPath = "$userPath;$path"
  }
}
[Environment]::SetEnvironmentVariable("ANDROID_HOME", $sdkRoot, "User")
[Environment]::SetEnvironmentVariable("ANDROID_SDK_ROOT", $sdkRoot, "User")
if (Test-Path -LiteralPath (Join-Path $androidStudioJbr "bin\java.exe")) {
  [Environment]::SetEnvironmentVariable("JAVA_HOME", $androidStudioJbr, "User")
}
[Environment]::SetEnvironmentVariable("Path", $userPath, "User")

$env:ANDROID_HOME = $sdkRoot
$env:ANDROID_SDK_ROOT = $sdkRoot
$env:Path = "$env:Path;$($pathsToAdd -join ';')"

Write-Host ""
Write-Host "Android Studio:"
Get-Item -LiteralPath "C:\Program Files\Android\Android Studio\bin\studio64.exe" | Select-Object FullName,Length

Write-Host ""
Write-Host "Android SDK:"
Get-ChildItem -LiteralPath $sdkRoot | Select-Object Name

Write-Host ""
Write-Host "Flutter doctor:"
& "C:\src\flutter\bin\flutter.bat" doctor
