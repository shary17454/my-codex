$ErrorActionPreference = "Stop"

$sdkRoot = Join-Path $env:LOCALAPPDATA "Android\Sdk"
$sdkManager = Join-Path $sdkRoot "cmdline-tools\latest\bin\sdkmanager.bat"
$androidStudioJbr = "C:\Program Files\Android\Android Studio\jbr"

if (Test-Path -LiteralPath (Join-Path $androidStudioJbr "bin\java.exe")) {
  $env:JAVA_HOME = $androidStudioJbr
  $env:Path = "$androidStudioJbr\bin;$env:Path"
  [Environment]::SetEnvironmentVariable("JAVA_HOME", $androidStudioJbr, "User")
}

Write-Host "Installing Android SDK packages after license acceptance..."
& $sdkManager --sdk_root=$sdkRoot "platform-tools" "platforms;android-36" "build-tools;36.0.0" "emulator"
if ($LASTEXITCODE -ne 0) {
  throw "sdkmanager package install failed."
}

$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
$pathsToAdd = @(
  "C:\src\flutter\bin",
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
[Environment]::SetEnvironmentVariable("Path", $userPath, "User")

$env:ANDROID_HOME = $sdkRoot
$env:ANDROID_SDK_ROOT = $sdkRoot
$env:Path = "$env:Path;$($pathsToAdd -join ';')"

Write-Host "Configuring Flutter Android SDK path..."
& "C:\src\flutter\bin\flutter.bat" config --android-sdk $sdkRoot

Write-Host ""
Write-Host "ADB:"
& (Join-Path $sdkRoot "platform-tools\adb.exe") version

Write-Host ""
Write-Host "Flutter doctor:"
& "C:\src\flutter\bin\flutter.bat" doctor

