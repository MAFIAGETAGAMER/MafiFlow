# Mocked integration test: no Dart process, EXE or MSIX is generated.
[CmdletBinding()]
param([Parameter(Mandatory=$true)][string] $FixtureRoot)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$fixtureTools = Join-Path $FixtureRoot 'tools'
New-Item -ItemType Directory -Path $fixtureTools -Force | Out-Null
foreach ($name in @('Empaquetar-MSIX.ps1','Leer-Version.ps1')) {
    Copy-Item -LiteralPath (Join-Path $PSScriptRoot $name) -Destination (Join-Path $fixtureTools $name) -Force
}
$verifier = @'
param([string] $PackagePath, [string] $ExpectedVersion)
@{PackagePath=$PackagePath;ExpectedVersion=$ExpectedVersion} | ConvertTo-Json | Set-Content -LiteralPath 'verification-call.json'
'@
Set-Content -LiteralPath (Join-Path $fixtureTools 'Verificar-MSIX-Generado.ps1') -Value $verifier
function dart {
    $global:mafiflowTestArguments = @($args)
    $global:LASTEXITCODE = 0
}
foreach ($case in @(@('1.5.12+28','1.5.12.0'),@('1.5.13+29','1.5.13.0'))) {
    Set-Content -LiteralPath (Join-Path $FixtureRoot 'pubspec.yaml') -Value ("version: " + $case[0])
    & (Join-Path $fixtureTools 'Empaquetar-MSIX.ps1')
    $captured = $global:mafiflowTestArguments
    $versionIndex = [Array]::IndexOf($captured,'--version')
    $nameIndex = [Array]::IndexOf($captured,'--output-name')
    if ($versionIndex -lt 0 -or $captured[$versionIndex+1] -cne $case[1]) { throw 'Version de empaquetado incorrecta' }
    if ($nameIndex -lt 0 -or $captured[$nameIndex+1] -cne ('MafiFlow_Store_x64_'+$case[1])) { throw 'Nombre de salida incorrecto' }
    $called = Get-Content -LiteralPath (Join-Path $FixtureRoot 'verification-call.json') -Raw | ConvertFrom-Json
    if ($called.ExpectedVersion -cne $case[1] -or $called.PackagePath -cne ('dist/MafiFlow_Store_x64_'+$case[1]+'.msix')) { throw 'Version del verificador o ruta no sincronizadas' }
}
Write-Host 'PASS: 2 casos de integracion simulada; argumentos, ruta y version esperada derivan del mismo pubspec. No se ha ejecutado Dart ni generado MSIX.'
