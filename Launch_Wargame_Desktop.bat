@echo off
:: ============================================================================
:: Launch Modern DEFCON Wargame Simulator in Desktop Flatscreen Mode
:: Ensures C:\GodotNET\dotnet (.NET 9 SDK) is prepended to PATH for Godot Mono
:: ============================================================================
set "PATH=C:\GodotNET\dotnet;%PATH%"
set "DOTNET_ROOT=C:\GodotNET\dotnet"
cd /d "%~dp0"
echo Starting DEFCON Holographic Wargame (Desktop Flatscreen)...
start "" "C:\dev\godot\Godot_v4.7.2-stable_mono_win64.exe" --xr-mode off
