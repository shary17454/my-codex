param(
  [Parameter(Mandatory = $true)]
  [string]$HtmlPath,

  [Parameter(Mandatory = $true)]
  [string]$PngPath
)

$ErrorActionPreference = "Stop"
$edgePath = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
$resolvedHtml = (Resolve-Path -LiteralPath $HtmlPath).Path
$resolvedPng = [System.IO.Path]::GetFullPath((Join-Path (Get-Location) $PngPath))
$pngDir = Split-Path -Parent $resolvedPng
if (-not (Test-Path -LiteralPath $pngDir)) {
  New-Item -ItemType Directory -Force -Path $pngDir | Out-Null
}
$profileDir = [System.IO.Path]::GetFullPath((Join-Path (Get-Location) ("tmp\saip\edge-preview-" + [System.Guid]::NewGuid().ToString("N"))))
New-Item -ItemType Directory -Force -Path $profileDir | Out-Null
$fileUrl = ([System.Uri]$resolvedHtml).AbsoluteUri

& $edgePath `
  "--headless=new" `
  "--disable-gpu" `
  "--disable-extensions" `
  "--user-data-dir=$profileDir" `
  "--screenshot=$resolvedPng" `
  "--window-size=1000,1400" `
  $fileUrl

for ($i = 0; $i -lt 20 -and -not (Test-Path -LiteralPath $resolvedPng); $i++) {
  Start-Sleep -Milliseconds 250
}

Get-Item -LiteralPath $resolvedPng | Select-Object FullName, Length, LastWriteTime
