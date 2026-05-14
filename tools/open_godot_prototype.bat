@echo off
setlocal

set "PROJECT_DIR=%~dp0..\godot"

where godot >nul 2>nul
if %errorlevel% equ 0 (
    godot --path "%PROJECT_DIR%"
    exit /b %errorlevel%
)

where godot4 >nul 2>nul
if %errorlevel% equ 0 (
    godot4 --path "%PROJECT_DIR%"
    exit /b %errorlevel%
)

echo Godot was not found on PATH.
echo Open this file manually in Godot 4.x:
echo %PROJECT_DIR%\project.godot
pause
