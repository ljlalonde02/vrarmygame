@echo off
title DEFCON: HOLOGRAPHIC COMMAND - Meta Quest 3 OpenXR Launcher
echo ============================================================================
echo   DEFCON: HOLOGRAPHIC COMMAND - LANCEMENT META QUEST 3 (OpenXR PCVR)
echo ============================================================================
echo.
echo Make sure your Meta Quest 3 is connected via:
echo   - Virtual Desktop (VDXR) or ALVR + SteamVR
echo   - Or use INSTALL_TO_META_QUEST_USB.bat to install the standalone Quest APK
echo.
"C:\Godot\Godot_v4.7.2-stable_mono_win64_console.exe" --path "%~dp0" --xr-mode on
pause
