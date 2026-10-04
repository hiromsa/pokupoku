# ユニットテストを実行する。終了コードが 0 なら全成功。
# 実行: powershell -NoProfile -File tools/run_tests.ps1
$ErrorActionPreference = 'Continue'

$ProjectRoot = Split-Path -Parent $PSScriptRoot
$GodotExe    = Join-Path $ProjectRoot 'tools/godot/Godot_v4.7.2-stable_win64_console.exe'

if (-not (Test-Path $GodotExe)) {
    Write-Error "Godot not found. Run tools/fetch_godot.ps1 first."
    exit 2
}

# class_name を解決するため .godot/ のグローバルクラスキャッシュが必要
if (-not (Test-Path (Join-Path $ProjectRoot '.godot/global_script_class_cache.cfg'))) {
    & $GodotExe --headless --path $ProjectRoot --editor --quit | Out-Null
}

& $GodotExe --headless --path $ProjectRoot --script res://tests/run_tests.gd
exit $LASTEXITCODE
