@echo off
rem Behemoth's Mountain Lion - development launcher (the single installer comes in step 8).
rem Needs Python 3.11+ from python.org on PATH. First run creates .venv and installs dependencies.
setlocal
cd /d "%~dp0"
if not exist ".venv\Scripts\python.exe" (
    echo Creating the virtual environment...
    py -3 -m venv .venv 2>nul || python -m venv .venv
    if errorlevel 1 (
        echo Python 3.11 or newer is needed: https://www.python.org/downloads/windows/
        pause
        exit /b 1
    )
)
".venv\Scripts\python.exe" -m pip install --disable-pip-version-check -q -r requirements.txt
".venv\Scripts\python.exe" -m bml %*
