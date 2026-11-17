@echo off
rem Copies this whole BUG'S-EYE VIEW folder to your Desktop.
rem Run it again after each update to refresh the copy (your own extra files stay).
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Make Desktop Folder.ps1"
pause
