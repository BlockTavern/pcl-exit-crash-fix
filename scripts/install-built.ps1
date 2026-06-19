param(
    [string]$PackRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..\..')).Path
)

$ErrorActionPreference = 'Stop'

$ProjectRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).Path
$GradleProperties = Join-Path $ProjectRoot 'gradle.properties'
$Properties = @{}

Get-Content -LiteralPath $GradleProperties | ForEach-Object {
    if ($_ -match '^\s*([^#][^=]+?)\s*=\s*(.*?)\s*$') {
        $Properties[$Matches[1]] = $Matches[2]
    }
}

$Version = $Properties['mod_version']
$ArchiveName = $Properties['archives_base_name']
$JarName = "$ArchiveName-$Version.jar"

$BuiltJar = Join-Path $ProjectRoot "build\local\libs\$JarName"
$ModsDir = Join-Path $PackRoot 'mods'

if (-not (Test-Path -LiteralPath $BuiltJar)) {
    throw "Cannot find built jar: $BuiltJar. Run scripts\build-local.ps1 first."
}

try {
    Get-ChildItem -LiteralPath $ModsDir -File -Filter 'pcl-exit-crash-fix-*.jar' | Remove-Item -Force
} catch {
    throw "Cannot replace the old pcl-exit-crash-fix jar. Close Minecraft/PCL first, then run this script again. Original error: $($_.Exception.Message)"
}

Copy-Item -LiteralPath $BuiltJar -Destination (Join-Path $ModsDir $JarName)
Write-Host "Installed $(Join-Path $ModsDir $JarName)"
