@echo off
:: ============================================================================
:: Launch Modern DEFCON Wargame Simulator in OpenXR VR Mode (Meta Quest 3 / PCVR)
:: Ensures C:\GodotNET\dotnet (.NET 9 SDK) is prepended to PATH for Godot Mono
:: ============================================================================
set "PATH=C:\GodotNET\dotnet;%PATH%"
set "DOTNET_ROOT=C:\GodotNET\dotnet"
cd /d "%~dp0"
echo Starting DEFCON Holographic Wargame (OpenXR VR Mode)...
start "" "C:\dev\godot\Godot_v4.7.2-stable_mono_win64.exe" --xr-mode on
