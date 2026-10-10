@echo off
cd /d "%~dp0"
title MafiFlow 1.3.2 - Windows Build
py -m pip install --upgrade pyinstaller
if errorlevel 1 goto error
py -m PyInstaller --noconfirm --clean --onefile --windowed --name MafiFlow --icon "assets\MafiFlow.ico" --add-data "assets;assets" app.py
if errorlevel 1 goto error
echo.
echo Listo: dist\MafiFlow.exe
pause
exit /b 0
:error
echo.
echo ERROR: No se pudo compilar el ejecutable.
pause
exit /b 1
