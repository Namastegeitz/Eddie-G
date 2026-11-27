# Makes "Cymatic Light Chamber" on your Desktop with the manual, print files, gobo library, show videos
# and the Android app (about 280 MB). Safe to run again: it only downloads what's missing.
#   irm https://namastegeitz.github.io/Eddie-G/cymatic-light-chamber/files/get-desktop-folder.ps1 | iex
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"
$site = "https://namastegeitz.github.io/Eddie-G/cymatic-light-chamber"
$dest = Join-Path ([Environment]::GetFolderPath("Desktop")) "Cymatic Light Chamber"
New-Item -ItemType Directory -Force -Path (Join-Path $dest "1 Start here") | Out-Null
Write-Host "Making: $dest"
$manifest = (Invoke-WebRequest -UseBasicParsing "$site/files/manifest.txt").Content -split "`n"
foreach ($line in $manifest) {
  if (-not $line.Trim()) { continue }
  $path, $folder = $line.TrimEnd("`r").Split("`t")
  $dir = Join-Path $dest $folder
  New-Item -ItemType Directory -Force -Path $dir | Out-Null
  $out = Join-Path $dir (Split-Path $path -Leaf)
  if ((Test-Path $out) -and ((Get-Item $out).Length -gt 0)) { Write-Host "  have  $folder\$(Split-Path $path -Leaf)"; continue }
  Write-Host "  get   $folder\$(Split-Path $path -Leaf)"
  Invoke-WebRequest -UseBasicParsing -Uri "$site/files/$path" -OutFile "$out.part"
  Move-Item -Force "$out.part" $out
}
Invoke-WebRequest -UseBasicParsing -Uri "$site/files/start-here.html" -OutFile (Join-Path $dest "1 Start here\Start here.html")
Write-Host "Done. Open '1 Start here\Start here.html' in the folder on your Desktop."
