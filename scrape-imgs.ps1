param([string]$url,[string]$outdir)
$ErrorActionPreference='Continue'
$ProgressPreference='SilentlyContinue'
New-Item -ItemType Directory -Path $outdir -Force | Out-Null
try {
  $r = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 30 -MaximumRedirection 5
} catch { Write-Host "FAIL $url : $_"; exit 1 }
$html = $r.Content
# Extract image URLs from src, srcset, data-src, style url()
$imgs = New-Object System.Collections.Generic.HashSet[string]
foreach($m in [regex]::Matches($html,'(?i)(?:src|data-src|data-lazy-src|data-orig-file|data-large-file)\s*=\s*["'']([^"'']+\.(?:jpe?g|png|webp|svg|gif))["'']')){ [void]$imgs.Add($m.Groups[1].Value) }
foreach($m in [regex]::Matches($html,'(?i)srcset\s*=\s*["'']([^"'']+)["'']')){
  foreach($part in $m.Groups[1].Value -split ','){
    $u = ($part.Trim() -split '\s+')[0]
    if($u -match '\.(jpe?g|png|webp|svg|gif)(\?.*)?$'){ [void]$imgs.Add($u) }
  }
}
foreach($m in [regex]::Matches($html,'(?i)url\(\s*["'']?([^"''\)]+\.(?:jpe?g|png|webp|svg|gif))["'']?\s*\)')){ [void]$imgs.Add($m.Groups[1].Value) }
# og:image
foreach($m in [regex]::Matches($html,'(?i)<meta[^>]+property=["'']og:image["''][^>]+content=["'']([^"'']+)["'']')){ [void]$imgs.Add($m.Groups[1].Value) }

$base = [Uri]$r.BaseResponse.ResponseUri
$downloaded = 0
$manifest = @()
foreach($src in $imgs){
  $s = $src.Trim()
  if($s -match '^data:' -or $s -match 'wayback|archive\.org/.+/images/|donate|wordsphere\.com|gravatar|wp-emoji|w3\.org|pixel\.gif') { continue }
  try {
    $abs = if($s -match '^https?:'){ [Uri]$s } elseif($s.StartsWith('//')){ [Uri]("https:$s") } else { [Uri]::new($base,$s) }
  } catch { continue }
  # Skip tiny theme assets
  if($abs.AbsolutePath -match '/wp-includes/|/themes/.+/(admin|icons?)/'){ continue }
  $name = [System.IO.Path]::GetFileName($abs.AbsolutePath)
  if(-not $name){ continue }
  $name = ($name -replace '[^\w\.\-]','_')
  if($name.Length -gt 80){ $name = $name.Substring($name.Length-80) }
  $out = Join-Path $outdir $name
  if(Test-Path -LiteralPath $out){ continue }
  try {
    Invoke-WebRequest -Uri $abs -OutFile $out -UseBasicParsing -TimeoutSec 30
    $size = (Get-Item -LiteralPath $out).Length
    if($size -lt 500){ Remove-Item -LiteralPath $out -Force; continue }
    $downloaded++
    $manifest += [PSCustomObject]@{file=$name;size=$size;src=$abs.ToString()}
  } catch { }
}
$manifest | ConvertTo-Json -Depth 3 | Out-File -LiteralPath (Join-Path $outdir '_manifest.json') -Encoding UTF8
Write-Host "[$outdir] Downloaded $downloaded image(s)"
