# Godot 4.7.2-stable win64 エディタを取得して tools/godot/ に展開するスクリプト
# 実行: powershell -NoProfile -File tools/fetch_godot.ps1
$ErrorActionPreference = 'Stop'

$Version    = '4.7.2-stable'
$ZipName    = "Godot_v${Version}_win64.exe.zip"
$ToolsDir   = Join-Path $PSScriptRoot 'godot'
$ZipPath    = Join-Path $ToolsDir $ZipName
$StatusPath = Join-Path $ToolsDir 'fetch_status.txt'
$Url        = "https://github.com/godotengine/godot/releases/download/${Version}/${ZipName}"

New-Item -ItemType Directory -Force -Path $ToolsDir | Out-Null
Set-Content -Path $StatusPath -Value 'DOWNLOADING' -Encoding utf8

try {
    Invoke-WebRequest -Uri $Url -OutFile $ZipPath -TimeoutSec 1800
    Set-Content -Path $StatusPath -Value 'EXTRACTING' -Encoding utf8

    Expand-Archive -Path $ZipPath -DestinationPath $ToolsDir -Force
    Remove-Item -Path $ZipPath -Force

    Set-Content -Path (Join-Path $ToolsDir 'VERSION.txt') -Value @(
        "Godot $Version (win64)",
        "Source: $Url",
        "Fetched: $(Get-Date -Format 'yyyy-MM-dd')"
    ) -Encoding utf8

    Set-Content -Path $StatusPath -Value 'DONE' -Encoding utf8
}
catch {
    Set-Content -Path $StatusPath -Value "ERROR: $_" -Encoding utf8
    throw
}
