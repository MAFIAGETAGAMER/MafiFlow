[CmdletBinding()]
param([Parameter(Mandatory=$true)][string] $PackagePath, [string] $ExpectedExePath = '')
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
Add-Type -AssemblyName System.IO.Compression.FileSystem
Add-Type -AssemblyName System.Drawing
if (!('MafiIconVerifier' -as [type])) {
Add-Type -TypeDefinition @'
using System;
using System.IO;
using System.Linq;
using System.Runtime.InteropServices;
public static class MafiIconVerifier {
 [DllImport("kernel32.dll",CharSet=CharSet.Unicode,SetLastError=true)] static extern IntPtr LoadLibraryEx(string f,IntPtr h,uint flags);
 [DllImport("kernel32.dll")] static extern bool FreeLibrary(IntPtr h);
 [DllImport("kernel32.dll",SetLastError=true)] static extern IntPtr FindResource(IntPtr h,IntPtr name,IntPtr type);
 [DllImport("kernel32.dll")] static extern IntPtr LoadResource(IntPtr h,IntPtr r);
 [DllImport("kernel32.dll")] static extern IntPtr LockResource(IntPtr r);
 [DllImport("kernel32.dll")] static extern uint SizeofResource(IntPtr h,IntPtr r);
 static byte[] Read(IntPtr h,int id,int type) {
   var r=FindResource(h,(IntPtr)id,(IntPtr)type);
   if(r==IntPtr.Zero) throw new Exception("Missing PE icon resource "+id);
   var data=new byte[checked((int)SizeofResource(h,r))];
   Marshal.Copy(LockResource(LoadResource(h,r)),data,0,data.Length); return data;
 }
 public static int Check(string exe,string ico) {
   var expected=File.ReadAllBytes(ico); int count=BitConverter.ToUInt16(expected,4);
   var h=LoadLibraryEx(exe,IntPtr.Zero,0x22); // DATAFILE | IMAGE_RESOURCE; never execute application code
   if(h==IntPtr.Zero) throw new Exception("Cannot read PE resources");
   try {
     var group=Read(h,101,14); // Flutter Runner.rc IDI_APP_ICON
     if(BitConverter.ToUInt16(group,4)!=count) throw new Exception("ICO frame count differs");
     for(int i=0;i<count;i++) {
       int e=6+i*16,g=6+i*14;
       // RC normalizes PNG ICO planes from 0 to 1; image bytes must still match exactly.
       for(int j=0;j<12;j++) {
         if(j==4 || j==5) continue;
         if(expected[e+j]!=group[g+j]) throw new Exception("ICO frame metadata differs");
       }
       int len=BitConverter.ToInt32(expected,e+8), offset=BitConverter.ToInt32(expected,e+12);
       var actual=Read(h,BitConverter.ToUInt16(group,g+12),3);
       if(!actual.SequenceEqual(expected.Skip(offset).Take(len))) throw new Exception("Executable contains a different icon");
     }
     return count;
   } finally { FreeLibrary(h); }
 }
}
'@
}
$zip = [IO.Compression.ZipFile]::OpenRead([IO.Path]::GetFullPath($PackagePath))
$exeTemp = Join-Path ([IO.Path]::GetTempPath()) ('mafiflow-icon-' + [Guid]::NewGuid().ToString('N') + '.exe')
try {
    function Read-Entry([string] $name) {
        $entry = $zip.GetEntry($name)
        if ($null -eq $entry) { throw "Falta $name en MSIX" }
        $stream = $entry.Open()
        $memory = [IO.MemoryStream]::new()
        try { $stream.CopyTo($memory); return ,$memory.ToArray() }
        finally { $stream.Dispose(); $memory.Dispose() }
    }
    [xml] $manifest = [Text.Encoding]::UTF8.GetString((Read-Entry 'AppxManifest.xml'))
    if ($manifest.Package.Identity.Name -cne 'Mafistudio.MafiFlow' -or
        $manifest.Package.Identity.Publisher -cne 'CN=728E4776-BB76-436A-88FF-F627802F7887' -or
        $manifest.Package.Identity.Version -ne '1.5.10.0' -or
        $manifest.Package.Properties.PublisherDisplayName -cne 'Mafistudio') { throw 'Identidad o version incorrecta' }
    if ($manifest.Package.Applications.Application.Executable -cne 'MafiFlow.exe') { throw 'Ejecutable incorrecto' }
    if ($manifest.Package.Applications.Application.Id -cne 'mafiflow') { throw 'Application Id distinto al instalado: debe ser mafiflow' }
    $visual = $manifest.Package.Applications.Application.VisualElements
    foreach ($reference in @($manifest.Package.Properties.Logo, $visual.Square44x44Logo,
        $visual.Square150x150Logo, $visual.DefaultTile.Square71x71Logo,
        $visual.DefaultTile.Square310x310Logo, $visual.DefaultTile.Wide310x150Logo)) {
        $null = Read-Entry ($reference.Replace('\','/'))
    }
    $checked = 0
    foreach ($file in Get-ChildItem (Join-Path $projectRoot 'store_assets') -Filter '*.png' -File) {
        [byte[]] $actual = Read-Entry ('Assets/' + $file.Name)
        $sha = [Security.Cryptography.SHA256]::Create()
        try {
            $actualHash = [BitConverter]::ToString($sha.ComputeHash($actual)).Replace('-','')
        } finally { $sha.Dispose() }
        if ($actualHash -ne (Get-FileHash $file.FullName -Algorithm SHA256).Hash) { throw "Logo incorrecto: $($file.Name)" }
        $checked++
    }
    $null = Read-Entry 'resources.pri'
    [byte[]] $packagedExe = Read-Entry 'MafiFlow.exe'
    if (!$ExpectedExePath) { $ExpectedExePath = Join-Path $projectRoot 'build/windows/x64/runner/Release/MafiFlow.exe' }
    [IO.File]::WriteAllBytes($exeTemp, $packagedExe)
    $releaseHash = (Get-FileHash -LiteralPath $ExpectedExePath -Algorithm SHA256).Hash
    if ((Get-FileHash -LiteralPath $exeTemp -Algorithm SHA256).Hash -cne $releaseHash) {
        throw 'El EXE dentro del MSIX no coincide con el EXE de Release'
    }
    $frames = [MafiIconVerifier]::Check($exeTemp, (Join-Path $projectRoot 'assets/MafiFlow.ico'))
    $report = [ordered]@{
        package = [IO.Path]::GetFileName($PackagePath)
        sha256 = (Get-FileHash $PackagePath -Algorithm SHA256).Hash
        identity = 'Mafistudio.MafiFlow'; version = '1.5.10.0'
        packagedLogoFilesVerified = $checked; embeddedExecutableIconFramesVerified = $frames
        packagedExecutableMatchesRelease = $true
        status = 'PASS'; runtimeTested = $false; storeCertified = $false
    }
    $report | ConvertTo-Json | Set-Content -LiteralPath ($PackagePath + '.verification.json') -Encoding utf8
    Write-Host "MSIX verificado: $checked logos y $frames resoluciones del icono integrado."
} finally {
    $zip.Dispose()
    if (Test-Path -LiteralPath $exeTemp) { Remove-Item -LiteralPath $exeTemp -Force }
}
