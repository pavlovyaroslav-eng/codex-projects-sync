param(
    [string]$DependencyDir = 'C:\Users\ACER-X-02\Downloads\DJi_Battery_Killer_ver.0.5beta2_01.02.2022_with_dlls'
)

$ErrorActionPreference = 'Stop'
$projectDir = $PSScriptRoot
$source = Join-Path $projectDir 'src\Tb30Bq76930Diag.cs'
$outputDir = Join-Path $projectDir 'dist'
$outputExe = Join-Path $outputDir 'Tb30Bq76930Diag.exe'
$compiler = 'C:\Windows\Microsoft.NET\Framework\v4.0.30319\csc.exe'

if (-not (Test-Path -LiteralPath $compiler)) {
    throw "C# compiler not found: $compiler"
}

$requiredDlls = 'SLABHIDtoSMBus.dll', 'SLABHIDDevice.dll'
foreach ($dll in $requiredDlls) {
    $dependency = Join-Path $DependencyDir $dll
    if (-not (Test-Path -LiteralPath $dependency)) {
        throw "Required CP2112 dependency not found: $dependency"
    }
}

New-Item -ItemType Directory -Force -Path $outputDir | Out-Null
& $compiler /nologo /target:exe /platform:x86 /optimize+ "/out:$outputExe" $source
if ($LASTEXITCODE -ne 0) {
    throw "C# compiler failed with exit code $LASTEXITCODE"
}

foreach ($dll in $requiredDlls) {
    Copy-Item -LiteralPath (Join-Path $DependencyDir $dll) -Destination (Join-Path $outputDir $dll) -Force
}

Get-FileHash -Algorithm SHA256 -LiteralPath $outputExe, (Join-Path $outputDir 'SLABHIDtoSMBus.dll'), (Join-Path $outputDir 'SLABHIDDevice.dll')
