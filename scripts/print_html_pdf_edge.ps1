param(
  [Parameter(Mandatory = $true)]
  [string]$HtmlPath,

  [Parameter(Mandatory = $true)]
  [string]$PdfPath
)

$ErrorActionPreference = "Stop"

$edgePath = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
if (-not (Test-Path -LiteralPath $edgePath)) {
  throw "Microsoft Edge was not found at $edgePath"
}

$resolvedHtml = (Resolve-Path -LiteralPath $HtmlPath).Path
$resolvedPdf = [System.IO.Path]::GetFullPath((Join-Path (Get-Location) $PdfPath))
$pdfDir = Split-Path -Parent $resolvedPdf
if (-not (Test-Path -LiteralPath $pdfDir)) {
  New-Item -ItemType Directory -Force -Path $pdfDir | Out-Null
}

$tmpRoot = (Resolve-Path -LiteralPath "tmp\saip").Path
$profileDir = Join-Path $tmpRoot ("edge-cdp-" + [System.Guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Force -Path $profileDir | Out-Null

$port = Get-Random -Minimum 19000 -Maximum 24000
$fileUrl = ([System.Uri]$resolvedHtml).AbsoluteUri
$args = @(
  "--headless=new",
  "--disable-gpu",
  "--disable-extensions",
  "--remote-debugging-port=$port",
  "--user-data-dir=$profileDir",
  "about:blank"
)

function Receive-CdpMessage {
  param([System.Net.WebSockets.ClientWebSocket]$Socket)
  $buffer = New-Object byte[] 1048576
  $segment = [ArraySegment[byte]]::new($buffer)
  $ms = New-Object System.IO.MemoryStream
  do {
    $result = $Socket.ReceiveAsync($segment, [Threading.CancellationToken]::None).GetAwaiter().GetResult()
    if ($result.Count -gt 0) {
      $ms.Write($buffer, 0, $result.Count)
    }
  } while (-not $result.EndOfMessage)
  [Text.Encoding]::UTF8.GetString($ms.ToArray())
}

function Send-CdpMessage {
  param(
    [System.Net.WebSockets.ClientWebSocket]$Socket,
    [string]$Message
  )
  $bytes = [Text.Encoding]::UTF8.GetBytes($Message)
  $segment = [ArraySegment[byte]]::new($bytes)
  $Socket.SendAsync($segment, [System.Net.WebSockets.WebSocketMessageType]::Text, $true, [Threading.CancellationToken]::None).GetAwaiter().GetResult()
}

$edge = $null
$ws = $null
try {
  $edge = Start-Process -FilePath $edgePath -ArgumentList $args -WindowStyle Hidden -PassThru

  $versionUrl = "http://127.0.0.1:$port/json/version"
  $ready = $false
  for ($i = 0; $i -lt 60; $i++) {
    try {
      Invoke-RestMethod -Uri $versionUrl -TimeoutSec 1 | Out-Null
      $ready = $true
      break
    }
    catch {
      Start-Sleep -Milliseconds 250
    }
  }
  if (-not $ready) {
    throw "Edge DevTools endpoint did not become ready."
  }

  $newUrl = "http://127.0.0.1:$port/json/new?" + [System.Uri]::EscapeDataString($fileUrl)
  try {
    $target = Invoke-RestMethod -Method Put -Uri $newUrl -TimeoutSec 5
  }
  catch {
    $target = Invoke-RestMethod -Uri $newUrl -TimeoutSec 5
  }

  $ws = [System.Net.WebSockets.ClientWebSocket]::new()
  $ws.ConnectAsync([Uri]$target.webSocketDebuggerUrl, [Threading.CancellationToken]::None).GetAwaiter().GetResult()

  $script:cdpId = 0
  function Invoke-Cdp {
    param(
      [string]$Method,
      [hashtable]$Params = @{}
    )
    $script:cdpId += 1
    $id = $script:cdpId
    $payload = @{ id = $id; method = $Method; params = $Params } | ConvertTo-Json -Depth 20 -Compress
    Send-CdpMessage -Socket $ws -Message $payload
    while ($true) {
      $message = Receive-CdpMessage -Socket $ws
      $json = $message | ConvertFrom-Json
      if ($json.id -eq $id) {
        if ($null -ne $json.error) {
          throw ($json.error | ConvertTo-Json -Depth 10)
        }
        return $json.result
      }
    }
  }

  Invoke-Cdp -Method "Page.enable" | Out-Null
  Invoke-Cdp -Method "Page.navigate" -Params @{ url = $fileUrl } | Out-Null
  Start-Sleep -Seconds 4

  $footer = "<div style='font-size:9px;width:100%;text-align:center;color:#555;font-family:Arial,Tahoma,sans-serif;direction:rtl;'>&#1589;&#1601;&#1581;&#1577; <span class='pageNumber'></span> &#1605;&#1606; <span class='totalPages'></span></div>"
  $result = Invoke-Cdp -Method "Page.printToPDF" -Params @{
    printBackground = $true
    displayHeaderFooter = $true
    headerTemplate = "<span></span>"
    footerTemplate = $footer
    preferCSSPageSize = $true
    marginTop = 0.35
    marginBottom = 0.55
    marginLeft = 0.4
    marginRight = 0.4
  }

  [IO.File]::WriteAllBytes($resolvedPdf, [Convert]::FromBase64String($result.data))
  try { Invoke-Cdp -Method "Browser.close" | Out-Null } catch {}
}
finally {
  if ($null -ne $ws) {
    try { $ws.Dispose() } catch {}
  }
  if ($null -ne $edge -and -not $edge.HasExited) {
    try { Stop-Process -Id $edge.Id -Force } catch {}
  }
}

Get-Item -LiteralPath $resolvedHtml, $resolvedPdf | Select-Object FullName, Length, LastWriteTime
