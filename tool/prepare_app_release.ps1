param(
    [Parameter(Mandatory = $true)][string]$ApkPath,
    [string]$Notes = 'Improvements and fixes for iTIWI.',
    [string]$AndroidSdk = "$env:LOCALAPPDATA/Android/sdk"
)

$ErrorActionPreference = 'Stop'
$repoPath = Split-Path -Parent $PSScriptRoot
$sitePath = Join-Path $repoPath 'site'
$apk = (Resolve-Path -LiteralPath $ApkPath).Path
$aapt = Get-ChildItem -LiteralPath (Join-Path $AndroidSdk 'build-tools') -Filter aapt.exe -Recurse |
    Sort-Object FullName -Descending | Select-Object -First 1
if (!$aapt) { throw 'Android SDK aapt.exe was not found. Pass -AndroidSdk with your SDK directory.' }
$badging = & $aapt.FullName dump badging $apk
if ($LASTEXITCODE -ne 0) { throw 'Could not read the APK metadata.' }
$packageLine = $badging | Where-Object { $_ -match '^package:' } | Select-Object -First 1
if ($packageLine -notmatch "name='com.ecoimpact.itiwi' versionCode='(\d+)' versionName='([^']+)'") {
    throw 'This APK is not an iTIWI release.'
}
$buildNumber = [long]$Matches[1]
$version = $Matches[2]
$hash = (Get-FileHash -LiteralPath $apk -Algorithm SHA256).Hash.ToLowerInvariant()
$manifestPath = Join-Path $sitePath 'app-release.json'
if (Test-Path -LiteralPath $manifestPath) {
    $previous = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
    if ($buildNumber -lt $previous.buildNumber -or
        ($buildNumber -eq $previous.buildNumber -and $hash -ne $previous.sha256)) {
        throw 'Increase the app build number before publishing a different APK.'
    }
}
$downloadPath = Join-Path $sitePath 'downloads'
New-Item -ItemType Directory -Path $downloadPath -Force | Out-Null
$filename = "itiwi-$buildNumber.apk"
Copy-Item -LiteralPath $apk -Destination (Join-Path $downloadPath $filename) -Force
$legacyPath = Join-Path $downloadPath 'itiwi.apk'
if ($apk -ne $legacyPath) { Copy-Item -LiteralPath $apk -Destination $legacyPath -Force }
$manifest = [ordered]@{
    packageName = 'com.ecoimpact.itiwi'
    version = $version
    buildNumber = $buildNumber
    apkUrl = "https://www.itiwi.online/downloads/$filename"
    sha256 = $hash
    notes = $Notes
} | ConvertTo-Json
[System.IO.File]::WriteAllText($manifestPath, $manifest + "`n", [System.Text.UTF8Encoding]::new($false))
Write-Output "Prepared iTIWI $version ($buildNumber). Deploy the site directory, including downloads/$filename and app-release.json."
