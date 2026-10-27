[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][string] $PackagePath,
    [string] $ExpectedExePath = '',
    [string] $ExpectedVersion = '1.5.11.0'
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
if (!$ExpectedExePath) { $ExpectedExePath = Join-Path $projectRoot 'build/windows/x64/runner/Release/MafiFlow.exe' }
Add-Type -AssemblyName System.IO.Compression.FileSystem
Add-Type -AssemblyName System.Drawing

# Compare low-resolution colour signatures; this is visual similarity, not byte equality.
function Get-LogoSignature([byte[]] $Bytes) {
    $stream = [IO.MemoryStream]::new($Bytes, $false)
    $original = [Drawing.Image]::FromStream($stream)
    $small = [Drawing.Bitmap]::new(16,16)
    $graphics = [Drawing.Graphics]::FromImage($small)
    try {
        $graphics.Clear([Drawing.Color]::Black)
        $graphics.InterpolationMode = [Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $graphics.DrawImage($original, [Drawing.Rectangle]::new(0,0,16,16))
        $values = [Collections.Generic.List[int]]::new()
        for ($y=0; $y -lt 16; $y++) {
            for ($x=0; $x -lt 16; $x++) {
                $pixel = $small.GetPixel($x,$y)
                $values.Add([int]$pixel.R); $values.Add([int]$pixel.G); $values.Add([int]$pixel.B)
            }
        }
        return ,$values.ToArray()
    } finally { $graphics.Dispose(); $small.Dispose(); $original.Dispose(); $stream.Dispose() }
}
function Get-Sha([byte[]] $Bytes) {
    $sha = [Security.Cryptography.SHA256]::Create()
    try { return [BitConverter]::ToString($sha.ComputeHash($Bytes)).Replace('-','') }
    finally { $sha.Dispose() }
}
$logoFile = Join-Path $projectRoot 'assets/MafiFlow-official.png'
$sourceSignature = Get-LogoSignature ([IO.File]::ReadAllBytes($logoFile))
$zip = [IO.Compression.ZipFile]::OpenRead([IO.Path]::GetFullPath($PackagePath))
$exeTemp = Join-Path ([IO.Path]::GetTempPath()) ('mafiflow-verified-' + [Guid]::NewGuid().ToString('N') + '.exe')
try {
    function Read-Entry([string] $Name) {
        $entry = $zip.GetEntry($Name)
        if ($null -eq $entry) { throw "Falta $Name en MSIX" }
        $stream = $entry.Open(); $memory = [IO.MemoryStream]::new()
        try { $stream.CopyTo($memory); return ,$memory.ToArray() }
        finally { $stream.Dispose(); $memory.Dispose() }
    }
    [xml] $manifest = [Text.Encoding]::UTF8.GetString((Read-Entry 'AppxManifest.xml'))
    if ($manifest.Package.Identity.Name -cne 'Mafistudio.MafiFlow' -or
        $manifest.Package.Identity.Publisher -cne 'CN=728E4776-BB76-436A-88FF-F627802F7887' -or
        $manifest.Package.Identity.Version -cne $ExpectedVersion -or
        $manifest.Package.Properties.PublisherDisplayName -cne 'Mafistudio') { throw 'Identidad o version incorrecta' }
    $app = $manifest.Package.Applications.Application
    if ($app.Id -cne 'mafiflow') { throw 'Application Id debe seguir siendo mafiflow; conserva name: mafiflow en pubspec.yaml' }
    $exeEntry = ([string]$app.Executable).Replace('\','/')
    if ($exeEntry -ine 'MafiFlow.exe') { throw 'Ejecutable inesperado' }
    [byte[]] $packagedExe = Read-Entry $exeEntry
    if ((Get-Sha $packagedExe) -cne (Get-FileHash -LiteralPath $ExpectedExePath -Algorithm SHA256).Hash) {
        throw 'El EXE del MSIX no coincide con el EXE de Release'
    }
    [IO.File]::WriteAllBytes($exeTemp,$packagedExe)
    & (Join-Path $PSScriptRoot 'Verificar-Icono-Exe.ps1') -ExePath $exeTemp
    $null = Read-Entry 'resources.pri'
    $previews = @('Square44x44Logo.targetsize-256.png', 'Square150x150Logo.scale-100.png', 'SmallTile.scale-100.png', 'StoreLogo.scale-100.png')
    $distances = [ordered]@{}
    $folder = [IO.Path]::GetDirectoryName([IO.Path]::GetFullPath($PackagePath))
    foreach ($name in $previews) {
        [byte[]] $png = Read-Entry ('Images/' + $name)
        $signature = Get-LogoSignature $png
        [double] $distance = 0
        for ($i=0; $i -lt $signature.Length; $i++) { $distance += [Math]::Abs($signature[$i] - $sourceSignature[$i]) }
        $distance /= $signature.Length
        $distances[$name] = [Math]::Round($distance,3)
        if ($distance -gt 20) { throw "Logo visualmente distinto del oficial: $name (distancia $distance)" }
        [IO.File]::WriteAllBytes((Join-Path $folder ('preview-' + $name)), $png)
    }
    $report = [ordered]@{
        status = 'PASS'
        version = $ExpectedVersion
        identity = [string]$manifest.Package.Identity.Name
        applicationId = [string]$app.Id
        packageSha256 = (Get-FileHash -LiteralPath $PackagePath -Algorithm SHA256).Hash
        packagedExeMatchesRelease = $true
        executableIconImagesMatchOfficialIcoExactly = $true
        officialLogoSourceSha256 = (Get-FileHash -LiteralPath $logoFile -Algorithm SHA256).Hash
        squareLogoVisualDistances = $distances
        pngVisualComparisonIsApproximate = $true
        runtimeTested = $false
        storeCertified = $false
    }
    $report | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath ($PackagePath + '.verification.json') -Encoding utf8
    Write-Host 'PASS: identidad, version, EXE identico, ICO oficial y cuatro logos del paquete.'
} finally {
    $zip.Dispose()
    if (Test-Path -LiteralPath $exeTemp) { Remove-Item -LiteralPath $exeTemp -Force }
}
