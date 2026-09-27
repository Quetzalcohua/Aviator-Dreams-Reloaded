param(
    [string]$JavaHome = $env:JAVA_HOME,
    [switch]$Clean
)
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
if (-not $JavaHome -and (Test-Path "$root/.tools/jdk-25/bin/javac.exe")) {
    $JavaHome = "$root/.tools/jdk-25"
}
if (-not $JavaHome -or -not (Test-Path "$JavaHome/bin/javac.exe")) {
    throw 'Supply -JavaHome pointing to a JDK 25 installation (not a JRE).'
}
$env:JAVA_HOME = (Resolve-Path $JavaHome).Path
$env:GRADLE_USER_HOME = "$root/.gradle-user-home"
Push-Location $root
try {
    $tasks = @(':fabric:build', '--no-daemon')
    if ($Clean) { $tasks = @('clean', ':fabric:clean') + $tasks }
    & ./gradlew.bat @tasks
    if ($LASTEXITCODE -ne 0) { throw "Gradle failed: $LASTEXITCODE" }
} finally { Pop-Location }
