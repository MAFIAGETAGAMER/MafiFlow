# Generate native runner separately so lib, pubspec and tests are never replaced.
[CmdletBinding()]
param()
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
Push-Location $projectRoot
try {
    if (Test-Path -LiteralPath 'windows/CMakeLists.txt') { return }
    $template = Join-Path $projectRoot '.dart_tool/native-template'
    if (Test-Path -LiteralPath $template) { throw 'Ya existe .dart_tool/native-template. Ejecuta flutter clean y repite.' }
    flutter create --no-pub --platforms=windows --project-name mafiflow --org com.mafistudio $template
    if ($LASTEXITCODE -ne 0) { throw 'No se pudo generar el runner Windows.' }
    Copy-Item -LiteralPath (Join-Path $template 'windows') -Destination (Join-Path $projectRoot 'windows') -Recurse
    if (!(Test-Path -LiteralPath 'windows/CMakeLists.txt')) { throw 'Falta el runner Windows.' }
}
finally { Pop-Location }
