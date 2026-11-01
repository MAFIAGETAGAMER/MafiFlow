[CmdletBinding()]
param()
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$release = & (Join-Path $PSScriptRoot 'Leer-Version.ps1') -ProjectRoot $projectRoot
Push-Location $projectRoot
try {
    Write-Host "Empaquetando app $($release.AppVersion), MSIX $($release.MsixVersion), archivo $($release.PackagePath)"
    $msixArgs = @(
        'run', 'msix:create', '--store', '--build-windows', 'false',
        '--architecture', 'x64', '--display-name', 'MafiFlow',
        '--identity-name', 'Mafistudio.MafiFlow',
        '--publisher', 'CN=728E4776-BB76-436A-88FF-F627802F7887',
        '--publisher-display-name', 'Mafistudio',
        '--version', $release.MsixVersion,
        '--logo-path', 'assets/MafiFlow-official.png', '--trim-logo', 'false',
        '--output-path', 'dist', '--output-name', $release.OutputName
    )
    & dart @msixArgs
    if ($LASTEXITCODE -ne 0) { throw 'Fallo generar MSIX' }
    & (Join-Path $PSScriptRoot 'Verificar-MSIX-Generado.ps1') -PackagePath $release.PackagePath -ExpectedVersion $release.MsixVersion
}
finally { Pop-Location }
