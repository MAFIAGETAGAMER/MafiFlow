# MafiFlow - Generador de MSIX para Microsoft Store
# Requiere Windows 10/11 + Windows SDK (MakeAppx.exe)
# Usa siempre la compilacion mas reciente del proyecto Flutter corregido.
[CmdletBinding()]
param(
    
    [ValidateNotNullOrEmpty()]
    [string] $IdentityName = 'Mafistudio.MafiFlow',

    
    [ValidateNotNullOrEmpty()]
    [string] $Publisher = 'CN=728E4776-BB76-436A-88FF-F627802F7887',

    
    [ValidateNotNullOrEmpty()]
    [string] $PublisherDisplayName = 'Mafistudio',

    [ValidatePattern('^[1-9][0-9]{0,4}\.[0-9]{1,5}\.[0-9]{1,5}\.0$')]
    [string] $Version = '1.5.10.0',

    [string] $OutputPath = '',

    [string] $ReleaseDirectory = '',

    [switch] $Overwrite
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function XmlEscape([string]$text) {
    return [System.Security.SecurityElement]::Escape($text)
}

# Los identificadores han de proceder del Partner Center para ESTA app.
if ($IdentityName -match '(EJEMPLO|PLACEHOLDER|YOUR_|IDENTITY_NAME)' -or
    $Publisher -match '(EJEMPLO|PLACEHOLDER|YOUR_|PUBLISHER_NAME)' -or
    $PublisherDisplayName -match '(EJEMPLO|PLACEHOLDER|YOUR_)') {
    throw 'Usa los valores REALES de Identidad de producto en Partner Center, no ejemplos.'
}

$parts = $Version.Split('.')
foreach ($part in $parts) {
    if ([int]$part -gt 65535) { throw 'Cada segmento de la version debe ser <= 65535.' }
}

$projectRoot = Split-Path -Parent $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($ReleaseDirectory)) {
    $ReleaseDirectory = Join-Path $projectRoot 'build\windows\x64\runner\Release'
}
$source = [System.IO.Path]::GetFullPath($ReleaseDirectory)
$assets = Join-Path $projectRoot 'store_assets'
& (Join-Path $PSScriptRoot 'Verificar-Icono-Exe.ps1') -ExePath (Join-Path $source 'MafiFlow.exe')
if (!(Test-Path -LiteralPath $source -PathType Container)) {
    throw 'No existe la carpeta Release compilada. Primero ejecuta flutter build windows --release.'
}
if (!(Test-Path -LiteralPath $assets -PathType Container)) {
    throw 'Faltan los iconos de Microsoft Store (store_assets).'
}
$expectedFiles = @(
    'MafiFlow.exe', 'flutter_windows.dll',
    'file_selector_windows_plugin.dll', 'url_launcher_windows_plugin.dll',
    'data\app.so', 'data\icudtl.dat',
    'data\flutter_assets\assets\logo.png'
)
foreach ($name in $expectedFiles) {
    $path = Join-Path $source $name
    if (!(Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "Falta un archivo esencial: $name"
    }
}

$sdkRoot = Join-Path ${env:ProgramFiles(x86)} 'Windows Kits\10\bin'
if (!(Test-Path -LiteralPath $sdkRoot)) {
    throw 'Windows SDK no encontrado. Instala el componente Windows 10/11 SDK desde Visual Studio Installer.'
}
$makeappx = Get-ChildItem -LiteralPath $sdkRoot -Filter 'makeappx.exe' -Recurse -File -ErrorAction SilentlyContinue |
    Where-Object { $_.FullName -match '[\\/]x64[\\/]makeappx\.exe$' } |
    Sort-Object FullName -Descending |
    Select-Object -First 1
if ($null -eq $makeappx) {
    throw 'No se encontro MakeAppx.exe x64 dentro de Windows SDK.'
}

if ([string]::IsNullOrWhiteSpace($OutputPath)) {
    $OutputPath = Join-Path $projectRoot ("dist\MafiFlow_Store_x64_$Version.msix")
}
$OutputPath = [System.IO.Path]::GetFullPath($OutputPath)
if (Test-Path -LiteralPath $OutputPath) {
    if (!$Overwrite) { throw "Archivo ya existe: $OutputPath. Usa -Overwrite si deseas reemplazarlo." }
    Remove-Item -LiteralPath $OutputPath -Force
}
$parent = Split-Path -Path $OutputPath -Parent
if (!(Test-Path -LiteralPath $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }

$staging = Join-Path ([System.IO.Path]::GetTempPath()) ("mafiflow-msix-" + [Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $staging | Out-Null
try {
    # Copiar TODA la carpeta release; el exe solo no es una app Flutter completa.
    Copy-Item -Path (Join-Path $source '*') -Destination $staging -Recurse -Force
    Copy-Item -LiteralPath $assets -Destination (Join-Path $staging 'Assets') -Recurse -Force

    $id = XmlEscape $IdentityName
    $publisherValue = XmlEscape $Publisher
    $publisherName = XmlEscape $PublisherDisplayName
    $manifest = @"
<?xml version="1.0" encoding="utf-8"?>
<Package
  xmlns="http://schemas.microsoft.com/appx/manifest/foundation/windows10"
  xmlns:uap="http://schemas.microsoft.com/appx/manifest/uap/windows10"
  xmlns:uap10="http://schemas.microsoft.com/appx/manifest/uap/windows10/10"
  xmlns:rescap="http://schemas.microsoft.com/appx/manifest/foundation/windows10/restrictedcapabilities"
  IgnorableNamespaces="uap uap10 rescap">
  <Identity Name="$id" Publisher="$publisherValue"
            Version="$Version" ProcessorArchitecture="x64" />
  <Properties>
    <DisplayName>MafiFlow</DisplayName>
    <PublisherDisplayName>$publisherName</PublisherDisplayName>
    <Description>MafiFlow personal finance manager</Description>
    <Logo>Assets\StoreLogo.png</Logo>
  </Properties>
  <Resources>
    <Resource Language="en-US" />
  </Resources>
  <Dependencies>
    <TargetDeviceFamily Name="Windows.Desktop"
        MinVersion="10.0.19041.0" MaxVersionTested="10.0.26100.0" />
  </Dependencies>
  <Capabilities>
    <rescap:Capability Name="runFullTrust" />
  </Capabilities>
  <Applications>
    <Application Id="mafiflow" Executable="MafiFlow.exe"
        uap10:RuntimeBehavior="packagedClassicApp"
        uap10:TrustLevel="mediumIL">
      <uap:VisualElements DisplayName="MafiFlow"
          Description="Personal finance management application"
          BackgroundColor="transparent"
          Square150x150Logo="Assets\Square150x150Logo.png"
          Square44x44Logo="Assets\Square44x44Logo.png">
        <uap:DefaultTile ShortName="MafiFlow" Square71x71Logo="Assets\Square71x71Logo.png"
            Wide310x150Logo="Assets\Wide310x150Logo.png" Square310x310Logo="Assets\Square310x310Logo.png" />
      </uap:VisualElements>
    </Application>
  </Applications>
</Package>
"@
    $manifestPath = Join-Path $staging 'AppxManifest.xml'
    [System.IO.File]::WriteAllText($manifestPath, $manifest, [System.Text.UTF8Encoding]::new($false))
    # Verificar XML ANTES de hacer el paquete.
    $xml = New-Object System.Xml.XmlDocument
    $xml.Load($manifestPath)

    $makepri = Join-Path (Split-Path $makeappx.FullName) 'makepri.exe'
    if (!(Test-Path $makepri)) { throw 'Falta MakePri.exe' }
    $priConfig = Join-Path $staging 'priconfig.xml'
    & $makepri createconfig /cf $priConfig /dq en-US /o
    if ($LASTEXITCODE -ne 0) { throw 'MakePri createconfig fallo' }
    # Keep scale and target-size variants in this one package, rather than resource packs.
    [xml] $config = Get-Content $priConfig -Raw
    $packaging = $config.SelectSingleNode('//packaging')
    if ($null -ne $packaging) { $null = $packaging.ParentNode.RemoveChild($packaging) }
    $config.Save($priConfig)
    & $makepri new /pr $staging /cf $priConfig /mn $manifestPath /of (Join-Path $staging 'resources.pri') /o
    if ($LASTEXITCODE -ne 0) { throw 'MakePri new fallo' }
    Remove-Item -LiteralPath $priConfig -Force

    Write-Host "MakeAppx: $($makeappx.FullName)"
    Write-Host "IdentityName: $IdentityName"
    Write-Host "Publisher: $Publisher"
    Write-Host "Output: $OutputPath"
    & $makeappx.FullName pack /v /h SHA256 /d $staging /p $OutputPath
    if ($LASTEXITCODE -ne 0 -or !(Test-Path -LiteralPath $OutputPath)) {
        throw "MakeAppx fallo. Codigo: $LASTEXITCODE"
    }
    & (Join-Path $PSScriptRoot 'Verificar-MSIX.ps1') -PackagePath $OutputPath
    Write-Host 'MSIX generado. Este paquete NO esta firmado; Microsoft Store lo firmara si supera la certificacion.' -ForegroundColor Green
    Write-Host "Archivo: $OutputPath"
    Write-Host 'IMPORTANTE: prueba en un equipo limpio y comprueba persistencia de datos, IA y navegacion antes del envio.' -ForegroundColor Yellow
}
finally {
    $resolvedStaging = [IO.Path]::GetFullPath($staging)
    $tempRoot = [IO.Path]::GetFullPath([IO.Path]::GetTempPath())
    if (!$resolvedStaging.StartsWith($tempRoot, [StringComparison]::OrdinalIgnoreCase) -or
        (Split-Path $resolvedStaging -Leaf) -notmatch '^mafiflow-msix-[a-f0-9]{32}$') { throw 'Ruta temporal no valida' }
    if (Test-Path -LiteralPath $resolvedStaging) { Remove-Item -LiteralPath $resolvedStaging -Force -Recurse }
}
