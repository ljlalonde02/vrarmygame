# Builds and installs builds/quest/vr_army_game_quest.apk directly onto a USB-connected Meta Quest headset.
$ErrorActionPreference = "Stop"
$ProjectRoot = Split-Path -Parent $PSScriptRoot
$GodotExe = "C:\Godot\Godot_v4.7.2-stable_mono_win64_console.exe"
$AdbExe = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"
$ApkPath = Join-Path $ProjectRoot "builds\quest\vr_army_game_quest.apk"
$CsprojPath = Join-Path $ProjectRoot "VRArmyGame.csproj"
$CsprojBak = Join-Path $ProjectRoot "VRArmyGame.csproj.bak"
$TemplateDir = "$env:APPDATA\Godot\export_templates\4.7.2.stable.mono"
$TpzUrl = "https://github.com/godotengine/godot/releases/download/4.7.2-stable/Godot_v4.7.2-stable_mono_export_templates.tpz"
$TpzZip = "$env:TEMP\Godot_v4.7.2-stable_mono_export_templates.zip"

Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host "  DEFCON 2028: HOLOGRAPHIC COMMAND & 688 SUB VR -- META QUEST USB DEPLOYER" -ForegroundColor Cyan
Write-Host "============================================================================" -ForegroundColor Cyan

# 1. Check (or Auto-Download) Godot 4.7.2 Mono Export Templates
if (-not (Test-Path "$TemplateDir\android_debug.apk")) {
    Write-Host "`n[1/4] Downloading Godot 4.7.2 .NET Mono Export Templates (~1.1 GB) from GitHub..." -ForegroundColor Yellow
    Write-Host "      URL: $TpzUrl" -ForegroundColor Gray
    & curl.exe -L -C - -o $TpzZip $TpzUrl
    Write-Host "      Extracting templates to $TemplateDir..." -ForegroundColor Yellow
    $ExtractTmp = "$env:TEMP\godot_templates_extract"
    if (Test-Path $ExtractTmp) { Remove-Item $ExtractTmp -Recurse -Force }
    Expand-Archive -Path $TpzZip -DestinationPath $ExtractTmp -Force
    New-Item -ItemType Directory -Force -Path $TemplateDir | Out-Null
    Move-Item -Path "$ExtractTmp\templates\*" -Destination $TemplateDir -Force
    Remove-Item $ExtractTmp -Recurse -Force
    Write-Host "      [OK] Godot 4.7.2 Export Templates installed!" -ForegroundColor Green
} else {
    Write-Host "`n[1/4] Godot 4.7.2 Export Templates already installed at $TemplateDir" -ForegroundColor Green
}

# 2. Export APK via Godot 4.7.2 (temporarily hide desktop .csproj so Android uses pure GDScript + OpenXR template)
Write-Host "`n[2/4] Exporting Meta Quest VR APK via Godot 4.7.2..." -ForegroundColor Green
if (Test-Path $CsprojPath) {
    Rename-Item -Path $CsprojPath -NewName "VRArmyGame.csproj.bak" -Force
}
try {
    $p = Start-Process -FilePath $GodotExe -ArgumentList "--headless --path `"$ProjectRoot`" --export-debug `"Meta Quest VR (OpenXR)`" `"$ApkPath`"" -PassThru -NoNewWindow
    $p.WaitForExit()
} finally {
    if (Test-Path $CsprojBak) {
        Rename-Item -Path $CsprojBak -NewName "VRArmyGame.csproj" -Force
    }
}

if (Test-Path $ApkPath) {
    $apkSizeMb = [math]::Round((Get-Item $ApkPath).Length / 1MB, 1)
    Write-Host "      [OK] Built signed APK: $ApkPath ($apkSizeMb MB)" -ForegroundColor Green
}

# 3. Check USB-connected Meta Quest via ADB
Write-Host "`n[3/4] Checking USB connection to Meta Quest headset via ADB..." -ForegroundColor Green
$adbOut = & $AdbExe devices
Write-Host ($adbOut | Out-String)

$connectedDevices = $adbOut | Where-Object { $_ -match "^\S+\s+device$" }
if ($connectedDevices) {
    Write-Host "[4/4] Installing $ApkPath onto Meta Quest via USB..." -ForegroundColor Green
    & $AdbExe install -r $ApkPath
    Write-Host "`n[OK] Launching DEFCON 2028: Holographic Command & 688 Sub VR in Immersive 3D VR on Quest..." -ForegroundColor Cyan
    & $AdbExe shell am start -a android.intent.action.MAIN -c com.oculus.intent.category.VR -n org.defcon.vrarmygame/com.godot.game.GodotAppLauncher
} else {
    Write-Host "[4/4] No USB-connected Meta Quest detected in 'adb devices' yet." -ForegroundColor Yellow
    Write-Host "      1. Plug your Meta Quest into this laptop via USB-C cable." -ForegroundColor Yellow
    Write-Host "      2. Put on the headset and click 'Allow USB Debugging'." -ForegroundColor Yellow
    Write-Host "      3. Run INSTALL_TO_META_QUEST_USB.bat again to install the built APK ($ApkPath)!" -ForegroundColor Yellow
}
