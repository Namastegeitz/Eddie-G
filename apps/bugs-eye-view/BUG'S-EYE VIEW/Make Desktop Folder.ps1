# Copies the BUG'S-EYE VIEW release folder to your Desktop (OneDrive Desktop too).
# Re-running refreshes the copy; files you added there yourself are kept.
$src  = $PSScriptRoot
$desk = [Environment]::GetFolderPath('Desktop')
$dst  = Join-Path $desk "BUG'S-EYE VIEW"
Write-Host "Copying to $dst ..."
robocopy "$src" "$dst" /E /XD _renders /XF .gdignore /NFL /NDL /NJH /NP | Out-Null
if ($LASTEXITCODE -ge 8) {
    Write-Host "Copy failed (robocopy code $LASTEXITCODE). Is the Desktop folder open in another program?" -ForegroundColor Red
    exit 1
}
Write-Host "Done. Opening the folder." -ForegroundColor Green
Start-Process explorer.exe "$dst"
