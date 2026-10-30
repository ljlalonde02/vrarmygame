@echo off
title DEFCON 2028 - Build and Install APK to Meta Quest via USB
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0tools\deploy_quest_apk.ps1"
pause
