param()
$ErrorActionPreference = 'Stop'
Set-Location 'C:\Users\User\Desktop\miller-institute-sites'
$map = @{
  'antibullyingconference' = 'img/logo.webp'
  'nsldc' = 'img/logo.jpg'
  'latinxleads' = 'img/logo.png'
  'millerinstitute' = 'img/logo.png'
}
$n = 0
foreach($site in $map.Keys){
  $logo = $map[$site]
  $files = Get-ChildItem -Path $site -Filter *.html -Recurse
  foreach($f in $files){
    $c = Get-Content -LiteralPath $f.FullName -Raw
    $orig = $c
    $navRepl = "<div class=""brand""><a href=""index.html""><img src=""/$logo"" alt=""logo"" class=""brand-logo""></a></div>"
    $footRepl = "<div class=""footer-brand""><img src=""/$logo"" alt=""logo"" class=""footer-logo""></div>"
    $c = [regex]::Replace($c,'(?s)<div class="brand">\s*<a href="index\.html">.*?</a>\s*</div>',$navRepl)
    $c = [regex]::Replace($c,'(?s)<div class="footer-brand">.*?</div>',$footRepl)
    if($c -ne $orig){
      Set-Content -LiteralPath $f.FullName -Value $c -NoNewline
      $n++
    }
  }
}
Write-Host "Updated $n files"
