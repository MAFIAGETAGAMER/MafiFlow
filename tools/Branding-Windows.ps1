# Aplica nombre, título y icono oficiales de MafiFlow al proyecto Windows generado.
[CmdletBinding()]
param()
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path -Parent $PSScriptRoot
Push-Location $projectRoot
try {
    $icon = 'assets/MafiFlow.ico'
    if (!(Test-Path -LiteralPath $icon)) { throw 'Falta assets/MafiFlow.ico' }

    $cmakePath = 'windows/CMakeLists.txt'
    if (!(Test-Path -LiteralPath $cmakePath)) { throw 'Primero ejecuta flutter create --platforms=windows ...' }
    $cmake = Get-Content -LiteralPath $cmakePath -Raw
    $cmake = [regex]::Replace($cmake, 'set\(BINARY_NAME\s+"[^"]+"\)', 'set(BINARY_NAME "MafiFlow")')
    if (!$cmake.Contains('set(BINARY_NAME "MafiFlow")')) { throw 'No se pudo poner MafiFlow como nombre del exe' }
    Set-Content -LiteralPath $cmakePath -Value $cmake -Encoding utf8

    $targetIcon = 'windows/runner/resources/app_icon.ico'
    New-Item -ItemType Directory -Force -Path (Split-Path $targetIcon) | Out-Null
    Copy-Item -LiteralPath $icon -Destination $targetIcon -Force

    if ((Get-FileHash $icon).Hash -ne (Get-FileHash $targetIcon).Hash) {
        throw 'El icono de runner no coincide con assets/MafiFlow.ico'
    }
    $rcPath = 'windows/runner/Runner.rc' 
    $rc = Get-Content -LiteralPath $rcPath -Raw
    $rc = [regex]::Replace($rc, '(?m)^\s*IDI_APP_ICON\s+ICON\s+[^\r\n]+', 'IDI_APP_ICON ICON "resources\\app_icon.ico"')
    if ($rc -notmatch 'IDI_APP_ICON\s+ICON') { throw 'Falta recurso IDI_APP_ICON' }
    $rc = [regex]::Replace($rc, '(VALUE\s+"(?:FileDescription|ProductName|InternalName)"\s*,\s*)"[^"]*"', '${1}"MafiFlow"')
    $rc = [regex]::Replace($rc, '(VALUE\s+"OriginalFilename"\s*,\s*)"[^"]*"', '${1}"MafiFlow.exe"')
    Set-Content -LiteralPath $rcPath -Value $rc -Encoding utf8

    $mainPath = 'windows/runner/main.cpp'
    $main = Get-Content -LiteralPath $mainPath -Raw
    $main = [regex]::Replace($main, 'window\.Create\(L"[^"]+"', 'window.Create(L"MafiFlow"')
    Set-Content -LiteralPath $mainPath -Value $main -Encoding utf8

    # El test de ejemplo que crea Flutter asume una interfaz distinta y no corresponde a MafiFlow.
    if (Test-Path -LiteralPath 'test/widget_test.dart') { Remove-Item 'test/widget_test.dart' -Force }
    Write-Host 'Nombre, icono y titulo nativos de MafiFlow configurados.' -ForegroundColor Green
}
finally {
    Pop-Location
}
