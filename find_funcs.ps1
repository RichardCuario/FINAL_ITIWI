param()
$content = [System.IO.File]::ReadAllLines("adminside/app.js")
for ($i = 0; $i -lt $content.Length; $i++) {
    if ($content[$i] -match 'async function saveNews') { Write-Output "saveNews: $($i+1)" }
    if ($content[$i] -match 'async function updateReportStatus') { Write-Output "updateReportStatus: $($i+1)" }
    if ($content[$i] -match 'async function saveService') { Write-Output "saveService: $($i+1)" }
}
