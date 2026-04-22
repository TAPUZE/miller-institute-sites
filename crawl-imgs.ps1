param([string]$startUrl,[string]$outdir,[int]$maxPages=30)
$ErrorActionPreference='Continue'
$ProgressPreference='SilentlyContinue'
New-Item -ItemType Directory -Path $outdir -Force | Out-Null
$outdir = (Resolve-Path $outdir).Path

$start = [Uri]$startUrl
# For archive.org URLs, detect the "original" host
$origHost = $start.Host
if($start.AbsolutePath -match '/web/\d+[^/]*/https?://([^/]+)'){ $origHost = $matches[1] }

$seen = New-Object System.Collections.Generic.HashSet[string]
$queue = New-Object System.Collections.Generic.Queue[string]
$queue.Enqueue($startUrl)
[void]$seen.Add($startUrl)
$allImgs = New-Object System.Collections.Generic.HashSet[string]

$pages = 0
while($queue.Count -gt 0 -and $pages -lt $maxPages){
  $u = $queue.Dequeue()
  try { $r = Invoke-WebRequest -Uri $u -UseBasicParsing -TimeoutSec 25 -MaximumRedirection 5 } catch { continue }
  $html = $r.Content
  $pages++
  $baseUri = [Uri]$r.BaseResponse.ResponseUri

  # Extract images
  foreach($m in [regex]::Matches($html,'(?i)(?:src|data-src|data-lazy-src|data-orig-file|data-large-file)\s*=\s*["'']([^"'']+\.(?:jpe?g|png|webp|gif))["'']')){ [void]$allImgs.Add($m.Groups[1].Value) }
  foreach($m in [regex]::Matches($html,'(?i)srcset\s*=\s*["'']([^"'']+)["'']')){
    foreach($part in $m.Groups[1].Value -split ','){
      $uu = ($part.Trim() -split '\s+')[0]
      if($uu -match '\.(jpe?g|png|webp|gif)(\?.*)?$'){ [void]$allImgs.Add($uu) }
    }
  }
  foreach($m in [regex]::Matches($html,'(?i)url\(\s*["'']?([^"''\)]+\.(?:jpe?g|png|webp|gif))["'']?\s*\)')){ [void]$allImgs.Add($m.Groups[1].Value) }
  foreach($m in [regex]::Matches($html,'(?i)<meta[^>]+property=["'']og:image["''][^>]+content=["'']([^"'']+)["'']')){ [void]$allImgs.Add($m.Groups[1].Value) }

  # Extract internal links
  foreach($m in [regex]::Matches($html,'(?i)href\s*=\s*["'']([^"''#]+)["'']')){
    $href = $m.Groups[1].Value.Trim()
    if($href.StartsWith('mailto:') -or $href.StartsWith('tel:') -or $href.StartsWith('javascript:')) { continue }
    try {
      $abs = if($href -match '^https?:'){ [Uri]$href } elseif($href.StartsWith('//')){ [Uri]("https:$href") } else { [Uri]::new($baseUri,$href) }
    } catch { continue }
    # Same-site check (either current host or the archived origin host)
    $isSame = ($abs.Host -eq $baseUri.Host) -or ($abs.AbsolutePath -match "/web/\d+[^/]*/https?://$([regex]::Escape($origHost))")
    if(-not $isSame){ continue }
    # Skip non-page extensions
    if($abs.AbsolutePath -match '\.(jpe?g|png|webp|gif|svg|pdf|zip|mp4|mov|css|js|ico|xml|json)(\?.*)?$'){ continue }
    $key = $abs.GetLeftPart([System.UriPartial]::Path)
    if($seen.Add($key)){ $queue.Enqueue($key) }
  }
}

Write-Host "  Crawled $pages page(s), found $($allImgs.Count) image URL(s)"

# Download images
$downloaded = 0
$manifest = @()
foreach($src in $allImgs){
  $s = $src.Trim()
  if($s -match '^data:' -or $s -match 'archive\.org/.+images/|donate|wordsphere\.com|gravatar|wp-emoji|w3\.org|pixel\.gif|spacer\.|blank\.gif|_w/|loading\.gif') { continue }
  try {
    $abs = if($s -match '^https?:'){ [Uri]$s } elseif($s.StartsWith('//')){ [Uri]("https:$s") } else { [Uri]::new($start,$s) }
  } catch { continue }
  if($abs.AbsolutePath -match '/wp-includes/|/themes/.+/(admin|icons?)/|/plugins/.+/assets/|wp-content/plugins/'){ continue }
  $name = [System.IO.Path]::GetFileName($abs.AbsolutePath)
  if(-not $name){ continue }
  $name = ($name -replace '[^\w\.\-]','_')
  if($name.Length -gt 80){ $name = $name.Substring($name.Length-80) }
  $out = Join-Path $outdir $name
  if(Test-Path -LiteralPath $out){ continue }
  try {
    Invoke-WebRequest -Uri $abs -OutFile $out -UseBasicParsing -TimeoutSec 30
    $size = (Get-Item -LiteralPath $out).Length
    if($size -lt 2000){ Remove-Item -LiteralPath $out -Force; continue }
    $downloaded++
    $manifest += [PSCustomObject]@{file=$name;size=$size;src=$abs.ToString()}
  } catch { }
}
$manifest | ConvertTo-Json -Depth 3 | Out-File -LiteralPath (Join-Path $outdir '_manifest.json') -Encoding UTF8
Write-Host "  Downloaded $downloaded image(s) to $outdir"
