$ErrorActionPreference = "Stop"

$out = (Resolve-Path "outputs\extracted_parts").Path
$tmp = (Resolve-Path "tmp").Path
$edge = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"

$items = @(
  @{ Html = "outputs\extracted_parts\patrol_y60_wiring_connectors_complete_card.html"; Pdf = "patrol_y60_wiring_connectors_complete_card.pdf"; Profile = "edge-profile-elec-ar" },
  @{ Html = "outputs\extracted_parts\patrol_y60_body_exterior_complete_card.html"; Pdf = "patrol_y60_body_exterior_complete_card.pdf"; Profile = "edge-profile-body-ar" },
  @{ Html = "outputs\extracted_parts\patrol_y60_interior_trim_seats_complete_card.html"; Pdf = "patrol_y60_interior_trim_seats_complete_card.pdf"; Profile = "edge-profile-int-ar" },
  @{ Html = "outputs\extracted_parts\patrol_y60_mechanical_complete_card.html"; Pdf = "patrol_y60_mechanical_complete_card.pdf"; Profile = "edge-profile-mech-ar" },
  @{ Html = "outputs\extracted_parts\patrol_y60_special_accessories_complete_card.html"; Pdf = "patrol_y60_special_accessories_complete_card.pdf"; Profile = "edge-profile-access-ar" },
  @{ Html = "outputs\extracted_parts\patrol_y60_hvac_coolers_vents_complete_card.html"; Pdf = "patrol_y60_hvac_coolers_vents_complete_card.pdf"; Profile = "edge-profile-hvac-ar" }
)

foreach ($item in $items) {
  $html = (Resolve-Path $item.Html).Path
  $pdf = Join-Path $out $item.Pdf
  $profile = Join-Path $tmp ("pdfs\" + $item.Profile)
  & $edge `
    --headless `
    --disable-gpu `
    --disable-extensions `
    --user-data-dir="$profile" `
    --no-pdf-header-footer `
    --print-to-pdf="$pdf" `
    "file:///$($html -replace '\\','/')" | Out-Null
}

Start-Sleep -Seconds 8
Get-ChildItem -LiteralPath $out -Filter "patrol_y60_*complete_card.pdf" |
  Sort-Object Name |
  Select-Object Name,Length
