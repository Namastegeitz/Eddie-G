@echo off
rem Puts a "Cosmic Saucer Drift" shortcut with the space icon on your desktop.
rem Double-click the shortcut to open the game in your browser.
set "URL=https://claude.ai/artifact/Wjris6Pjst5K54bF6z8MUY"
set "DIR=%LOCALAPPDATA%\Cosmic Saucer Drift"
if not exist "%DIR%" mkdir "%DIR%"
copy /Y "%~dp0cosmic-saucer-drift.ico" "%DIR%\cosmic-saucer-drift.ico" >nul
for /f "usebackq delims=" %%D in (`powershell -NoProfile -Command "[Environment]::GetFolderPath('Desktop')"`) do set "DESK=%%D"
if not defined DESK set "DESK=%USERPROFILE%\Desktop"
> "%DESK%\Cosmic Saucer Drift.url" (
  echo [InternetShortcut]
  echo URL=%URL%
  echo IconFile=%DIR%\cosmic-saucer-drift.ico
  echo IconIndex=0
)
echo.
echo Done: "Cosmic Saucer Drift" is on your desktop.
echo (If it shows a plain icon for a moment, Windows is still refreshing its icon cache.)
pause
