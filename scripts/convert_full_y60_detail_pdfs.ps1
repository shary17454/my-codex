$out = (Resolve-Path 'output\pdf\full_y60').Path
$tmp = (Resolve-Path 'tmp').Path
$profile = Join-Path $tmp 'edge-profile-full-y60-detail'
$edge = 'C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe'

Get-ChildItem -LiteralPath $out -Filter '*.html' | Sort-Object Name | ForEach-Object {
    $pdf = [System.IO.Path]::ChangeExtension($_.FullName, '.pdf')
    $url = 'file:///' + ($_.FullName -replace '\\', '/')
    & $edge --headless --disable-gpu --disable-extensions --user-data-dir="$profile" --no-pdf-header-footer --print-to-pdf="$pdf" "$url" | Out-Null
}

Start-Sleep -Seconds 5
Get-ChildItem -LiteralPath $out -Filter '*.pdf' | Sort-Object Name | Select-Object Name,Length
