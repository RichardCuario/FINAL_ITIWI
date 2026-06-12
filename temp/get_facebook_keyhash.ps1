$keystore = "$env:USERPROFILE\.android\debug.keystore"
$keytool = if ($env:JAVA_HOME -and (Test-Path (Join-Path $env:JAVA_HOME 'bin\keytool.exe'))) {
  Join-Path $env:JAVA_HOME 'bin\keytool.exe'
} else {
  'keytool'
}

$tempCert = Join-Path $env:TEMP 'facebook_debug_cert.der'
& $keytool -exportcert -alias androiddebugkey -keystore $keystore -storepass android -file $tempCert | Out-Null
$bytes = [System.IO.File]::ReadAllBytes($tempCert)
$sha1 = [System.Security.Cryptography.SHA1]::Create().ComputeHash($bytes)
[Convert]::ToBase64String($sha1)
Remove-Item $tempCert -ErrorAction SilentlyContinue
