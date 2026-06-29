param(
  [Parameter(Mandatory = $true)]
  [string]$DocxPath,

  [Parameter(Mandatory = $true)]
  [string]$PdfPath
)

$ErrorActionPreference = "Stop"

$resolvedDocx = (Resolve-Path -LiteralPath $DocxPath).Path
$resolvedPdf = [System.IO.Path]::GetFullPath((Join-Path (Get-Location) $PdfPath))
$pdfDir = Split-Path -Parent $resolvedPdf
if (-not (Test-Path -LiteralPath $pdfDir)) {
  New-Item -ItemType Directory -Force -Path $pdfDir | Out-Null
}

$word = $null
$doc = $null
try {
  $word = New-Object -ComObject Word.Application
  $word.Visible = $false
  $word.DisplayAlerts = 0

  $doc = $word.Documents.Open($resolvedDocx, $false, $false)

  foreach ($story in $doc.StoryRanges) {
    $range = $story
    while ($null -ne $range) {
      $range.Fields.Update() | Out-Null
      $range = $range.NextStoryRange
    }
  }

  foreach ($toc in $doc.TablesOfContents) {
    $toc.Update()
  }

  foreach ($tof in $doc.TablesOfFigures) {
    $tof.Update()
  }

  $doc.Repaginate()
  $doc.Save()
  $doc.ExportAsFixedFormat($resolvedPdf, 17)
  $doc.Close($true)
  $doc = $null
}
finally {
  if ($null -ne $doc) {
    $doc.Close($false)
  }
  if ($null -ne $word) {
    $word.Quit()
  }
}

Get-Item -LiteralPath $resolvedDocx, $resolvedPdf | Select-Object FullName, Length, LastWriteTime
