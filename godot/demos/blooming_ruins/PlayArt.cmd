@echo off
setlocal
if not defined GODOT_EXE set "GODOT_EXE=%USERPROFILE%\Downloads\Godot_v4.6.2-stable_win64\Godot_v4.6.2-stable_win64.exe"
if not exist "%GODOT_EXE%" (
  echo Set GODOT_EXE to your Godot executable, or open ArtPreview.tscn in the editor and press F6.
  pause
  exit /b 1
)
set "APPDATA=%~dp0user-data"
set "LOCALAPPDATA=%~dp0user-local"
set "BLOOM_CAPTURE="
if not exist "%APPDATA%" mkdir "%APPDATA%"
if not exist "%LOCALAPPDATA%" mkdir "%LOCALAPPDATA%"
"%GODOT_EXE%" --path "%~dp0..\.." --rendering-method gl_compatibility res://demos/blooming_ruins/ArtPreview.tscn
