@echo off
where node >nul 2>nul
if %errorlevel%==0 (
  node "%~dp0check_godot_stability.mjs" %*
) else (
  echo Node.js is required to run this check.
  exit /b 1
)
