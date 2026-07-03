$out = (Resolve-Path 'output\pdf\full_y60').Path
$tmp = (Resolve-Path 'tmp').Path
$profile = Join-Path $tmp 'edge-profile-full-y60-detail-single'
$edge = 'C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe'

$names = @(
    '75473392c7ca_Australia_RHD_PICKUP_TB42S_STD.html',
    '7c1844e0802d_Australia_RHD_HARDTOP_TD42_STD.html',
    '9454a4eac8ca_Australia_RHD_WAGON_TD42_STD.html'
)

foreach ($name in $names) {
    $html = Join-Path $out $name
    $pdf = [System.IO.Path]::ChangeExtension($html, '.pdf')
    $url = 'file:///' + ($html -replace '\\', '/')
    & $edge --headless --disable-gpu --disable-extensions --user-data-dir="$profile" --no-pdf-header-footer --print-to-pdf="$pdf" "$url" | Out-Null
    Start-Sleep -Seconds 3
}

Get-ChildItem -LiteralPath $out -Filter '*.pdf' | Sort-Object Name | Select-Object Name,Length
