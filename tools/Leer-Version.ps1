[CmdletBinding()]
param([string] $ProjectRoot = (Split-Path -Parent $PSScriptRoot))
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$source = Get-Content -LiteralPath (Join-Path $ProjectRoot 'pubspec.yaml') -Raw
$match = [regex]::Match($source, '(?m)^version:\s*(\d+\.\d+\.\d+)\+(\d+)\s*$')
if (!$match.Success) { throw 'pubspec.yaml debe contener version: X.Y.Z+N' }
$app = $match.Groups[1].Value + '+' + $match.Groups[2].Value
$msix = $match.Groups[1].Value + '.0'
foreach ($segment in $msix.Split('.')) {
    if ([long]$segment -gt 65535) { throw "Version MSIX fuera de rango: $msix" }
}
if ([int]$msix.Split('.')[0] -lt 1) { throw "Version MSIX invalida: $msix" }
[pscustomobject]@{
    AppVersion = $app
    MsixVersion = $msix
    OutputName = "MafiFlow_Store_x64_$msix"
    PackagePath = "dist/MafiFlow_Store_x64_$msix.msix"
}
