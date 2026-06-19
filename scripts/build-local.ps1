param(
    [string]$PackRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..\..')).Path,
    [switch]$NoInstall
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

$MinecraftRoot = (Resolve-Path -LiteralPath (Join-Path $PackRoot '..\..')).Path
$LibrariesRoot = Join-Path $MinecraftRoot 'libraries'
$FabricApiJar = Join-Path $PackRoot 'mods\fabric-api-0.102.0+1.21.jar'
$MixinJar = Join-Path $LibrariesRoot 'net\fabricmc\sponge-mixin\0.15.4+mixin.0.8.7\sponge-mixin-0.15.4+mixin.0.8.7.jar'

if (-not (Test-Path -LiteralPath $FabricApiJar)) {
    throw "Cannot find Fabric API jar: $FabricApiJar"
}

if (-not (Test-Path -LiteralPath $MixinJar)) {
    throw "Cannot find Sponge Mixin jar: $MixinJar"
}

$BuildRoot = Join-Path $ProjectRoot 'build\local'
$ClassesDir = Join-Path $BuildRoot 'classes'
$TempDir = Join-Path $BuildRoot 'tmp'
$LibDir = Join-Path $BuildRoot 'libs'

if (Test-Path -LiteralPath $BuildRoot) {
    Remove-Item -LiteralPath $BuildRoot -Recurse -Force
}

foreach ($Dir in @($ClassesDir, $TempDir, $LibDir)) {
    [System.IO.Directory]::CreateDirectory($Dir) | Out-Null
}

Push-Location -LiteralPath $TempDir
jar xf $FabricApiJar META-INF/jars/fabric-registry-sync-v0-0.102.0.jar
Pop-Location

$RegistrySyncJar = Join-Path $TempDir 'META-INF\jars\fabric-registry-sync-v0-0.102.0.jar'
if (-not (Test-Path -LiteralPath $RegistrySyncJar)) {
    throw "Cannot extract fabric-registry-sync-v0 from Fabric API jar."
}

$SourceFile = Join-Path $ProjectRoot 'src\main\java\xiaopa\pclexitcrashfix\mixin\RegistrySyncManagerMixin.java'
$ClassPath = @($MixinJar, $RegistrySyncJar) -join [IO.Path]::PathSeparator

javac -proc:none -encoding UTF-8 -cp $ClassPath -d $ClassesDir $SourceFile

$ResourcesRoot = Join-Path $ProjectRoot 'src\main\resources'
$ModJson = Get-Content -LiteralPath (Join-Path $ResourcesRoot 'fabric.mod.json') -Raw
$ModJson = $ModJson.Replace('${version}', $Version)
$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText((Join-Path $ClassesDir 'fabric.mod.json'), $ModJson, $Utf8NoBom)
Copy-Item -LiteralPath (Join-Path $ResourcesRoot 'pcl-exit-crash-fix.mixins.json') -Destination $ClassesDir

$JarPath = Join-Path $LibDir $JarName
Push-Location -LiteralPath $ClassesDir
jar --create --file $JarPath .
Pop-Location

if (-not $NoInstall) {
    $ModsDir = Join-Path $PackRoot 'mods'
    try {
        Get-ChildItem -LiteralPath $ModsDir -File -Filter 'pcl-exit-crash-fix-*.jar' | Remove-Item -Force
    } catch {
        throw "Cannot replace the old pcl-exit-crash-fix jar. Close Minecraft/PCL first, then run this script again. Original error: $($_.Exception.Message)"
    }

    Copy-Item -LiteralPath $JarPath -Destination (Join-Path $ModsDir $JarName)
}

Write-Host "Built $JarPath"
if (-not $NoInstall) {
    Write-Host "Installed to $(Join-Path $PackRoot "mods\$JarName")"
}
