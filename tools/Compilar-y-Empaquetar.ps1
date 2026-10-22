# Ejecutar desde Windows 10/11 con Flutter, Visual Studio C++ y Windows SDK instalados.
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][string] $IdentityName,
    [Parameter(Mandatory=$true)][string] $Publisher,
    [Parameter(Mandatory=$true)][string] $PublisherDisplayName
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
function Run-Flutter([string[]] $argsList) {
    & flutter @argsList
    if ($LASTEXITCODE -ne 0) { throw "Flutter fallo: flutter $($argsList -join ' ')" }
}
Push-Location $projectRoot
try {
    Run-Flutter -argsList @('config', '--enable-windows-desktop')
    Run-Flutter -argsList @('create', '--platforms=windows', '--project-name', 'mafiflow', '--org', 'com.mafistudio', '.')
    & (Join-Path $PSScriptRoot 'Branding-Windows.ps1')
    Run-Flutter -argsList @('pub', 'get')
    Run-Flutter -argsList @('analyze', '--no-fatal-infos', '--no-fatal-warnings')
    Run-Flutter -argsList @('test', 'test/help_center_test.dart')
    Run-Flutter -argsList @('build', 'windows', '--release')
    & (Join-Path $PSScriptRoot 'Crear-MSIX.ps1') -IdentityName $IdentityName -Publisher $Publisher -PublisherDisplayName $PublisherDisplayName -Version '1.5.6.0' -Overwrite
    Write-Host 'Compilacion y MSIX para Partner Center generados.' -ForegroundColor Green
}
finally { Pop-Location }
