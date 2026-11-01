@echo off
:: ============================================================================
:: Launch Godot 4.7.2 Mono Editor with .NET 9 SDK Environment Pre-configured
:: ============================================================================
set "PATH=C:\GodotNET\dotnet;%PATH%"
set "DOTNET_ROOT=C:\GodotNET\dotnet"
cd /d "%~dp0"
echo Opening Project in Godot 4.7.2 Mono Editor...
start "" "C:\dev\godot\Godot_v4.7.2-stable_mono_win64.exe" --editor "%~dp0project.godot"
