[CmdletBinding()]
param([string] $ExePath = '')
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
if (!$ExePath) { $ExePath = Join-Path $projectRoot 'build/windows/x64/runner/Release/MafiFlow.exe' }
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

$frames = [MafiIconVerifier]::Check([IO.Path]::GetFullPath($ExePath), (Join-Path $projectRoot 'assets/MafiFlow.ico'))
Write-Host "PASS: $frames resoluciones del ICO coinciden byte por byte con el EXE."
