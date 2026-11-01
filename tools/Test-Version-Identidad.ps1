[CmdletBinding()]
param([Parameter(Mandatory=$true)][string] $FixtureRoot)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
New-Item -ItemType Directory -Path $FixtureRoot -Force | Out-Null
Set-Content -LiteralPath (Join-Path $FixtureRoot 'pubspec.yaml') -Value 'version: 1.5.12+28' -Encoding utf8
$release = & (Join-Path $PSScriptRoot 'Leer-Version.ps1') -ProjectRoot $FixtureRoot
if ($release.AppVersion -cne '1.5.12+28' -or $release.MsixVersion -cne '1.5.12.0' -or $release.PackagePath -cne 'dist/MafiFlow_Store_x64_1.5.12.0.msix') { throw 'Versiones y ruta no sincronizadas' }
$text = '<Package><Identity Name="Mafistudio.MafiFlow" Publisher="CN=728E4776-BB76-436A-88FF-F627802F7887" Version="1.5.12.0"/><Properties><PublisherDisplayName>Mafistudio</PublisherDisplayName></Properties></Package>'
& (Join-Path $PSScriptRoot 'Verificar-Identidad-MSIX.ps1') -Manifest ([xml]$text) -ExpectedVersion $release.MsixVersion
$cases = @('Identity.Name','Identity.Publisher','Identity.Version','Properties.PublisherDisplayName')
foreach ($field in $cases) {
    [xml] $fixture = $text
    switch ($field) {
        'Identity.Name' { $fixture.Package.Identity.Name = 'Incorrecto' }
        'Identity.Publisher' { $fixture.Package.Identity.Publisher = 'CN=Incorrecto' }
        'Identity.Version' { $fixture.Package.Identity.Version = '1.5.11.0' }
        'Properties.PublisherDisplayName' { $fixture.Package.Properties.PublisherDisplayName = 'Incorrecto' }
    }
    $message = ''
    try {
        & (Join-Path $PSScriptRoot 'Verificar-Identidad-MSIX.ps1') -Manifest $fixture -ExpectedVersion $release.MsixVersion -ReportPath (Join-Path $FixtureRoot ($field + '.json'))
    } catch { $message = $_.Exception.Message }
    if (!$message.Contains($field) -or !$message.Contains('esperado=[') -or !$message.Contains('encontrado=[')) { throw "No se detecto o explico el desajuste $field" }
    $report = @(Get-Content -LiteralPath (Join-Path $FixtureRoot ($field + '.json')) -Raw | ConvertFrom-Json)
    if ($report.Count -ne 4) { throw 'Informe de identidad incompleto' }
}
Write-Host 'PASS: 6 casos sinteticos (lectura de version, identidad valida y cuatro campos incorrectos). No es una compilacion ni validacion de MSIX real.'
