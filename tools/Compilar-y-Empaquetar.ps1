# Ejecutar desde Windows 10/11 con Flutter, Visual Studio C++ y Windows SDK instalados.
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][version] $PublishedVersion,
    [string] $IdentityName = 'Mafistudio.MafiFlow',
    [string] $Publisher = 'CN=728E4776-BB76-436A-88FF-F627802F7887',
    [string] $PublisherDisplayName = 'Mafistudio'
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
function Run-Flutter([string[]] $argsList) {
    & flutter @argsList
    if ($LASTEXITCODE -ne 0) { throw "Flutter fallo: flutter $($argsList -join ' ')" }
}
if ($IdentityName -cne 'Mafistudio.MafiFlow' -or $Publisher -cne 'CN=728E4776-BB76-436A-88FF-F627802F7887' -or $PublisherDisplayName -cne 'Mafistudio') {
    throw 'Esta actualizacion debe conservar la identidad de MafiFlow en Store.'
}
Push-Location $projectRoot
try {
    $release = & (Join-Path $PSScriptRoot 'Leer-Version.ps1')
    if ([version]$release.MsixVersion -le $PublishedVersion) { throw 'Incrementa la version: debe superar la publicada en Partner Center.' }
    Run-Flutter -argsList @('clean')
    Run-Flutter -argsList @('config', '--enable-windows-desktop')
    & (Join-Path $PSScriptRoot 'Preparar-Windows.ps1')
    & (Join-Path $PSScriptRoot 'Branding-Windows.ps1')
    Run-Flutter -argsList @('pub', 'get')
    Run-Flutter -argsList @('analyze', '--no-fatal-infos', '--no-fatal-warnings')
    Run-Flutter -argsList @('test')
    & (Join-Path $PSScriptRoot 'Branding-Windows.ps1')
    Run-Flutter -argsList @('build', 'windows', '--release')
    & (Join-Path $PSScriptRoot 'Verificar-Icono-Exe.ps1')
    & (Join-Path $PSScriptRoot 'Empaquetar-MSIX.ps1')
    Write-Host 'Compilacion y MSIX para Partner Center generados.' -ForegroundColor Green
}
finally { Pop-Location }
