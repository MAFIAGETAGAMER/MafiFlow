[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][xml] $Manifest,
    [Parameter(Mandatory=$true)][string] $ExpectedVersion,
    [string] $ReportPath = ''
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$checks = @(
    [pscustomobject]@{ Field='Identity.Name'; Expected='Mafistudio.MafiFlow'; Actual=[string]$Manifest.Package.Identity.Name }
    [pscustomobject]@{ Field='Identity.Publisher'; Expected='CN=728E4776-BB76-436A-88FF-F627802F7887'; Actual=[string]$Manifest.Package.Identity.Publisher }
    [pscustomobject]@{ Field='Identity.Version'; Expected=$ExpectedVersion; Actual=[string]$Manifest.Package.Identity.Version }
    [pscustomobject]@{ Field='Properties.PublisherDisplayName'; Expected='Mafistudio'; Actual=[string]$Manifest.Package.Properties.PublisherDisplayName }
)
if ($ReportPath) { $checks | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath $ReportPath -Encoding utf8 }
$mismatches = @($checks | Where-Object { $_.Actual -cne $_.Expected })
foreach ($check in $checks) {
    Write-Host "$($check.Field): esperado=[$($check.Expected)] encontrado=[$($check.Actual)]"
}
if ($mismatches.Count -gt 0) {
    $details = ($mismatches | ForEach-Object { "$($_.Field): esperado=[$($_.Expected)] encontrado=[$($_.Actual)]" }) -join '; '
    throw "Identidad o version incorrecta: $details"
}
