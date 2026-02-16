# index file URL
$indexUrl = "https://files.singular-devops.com/challenges/01-applogs/index.txt"
#Base URL for log files
$baseUrl = "https://files.singular-devops.com/challenges/01-applogs/"
#local paths
$indexPath = "./index.txt"
$logsFolder = "./logs"

Write-Host "Starting script to download log files from index..."

$logsFolder | Where-Object { -not (Test-Path $_) } | ForEach-Object {
    New-Item -ItemType Directory -Path $_ | Out-Null
    Write-Host "Created logs folder at $_."
}

Write-Host "Downloading index file..."

try {
    Invoke-WebRequest -Uri $indexUrl -OutFile $indexPath -ErrorAction Stop
    Write-Host "File downloaded successfully."
}
catch {
    Write-Host "Download failed!"
    Write-Host $_.Exception.Message
    exit 1

}
#read index files
Write-Host "Reading index file..."

$files = Get-Content $indexPath

Write-Host "Files listed in index: "
$files
#download each log file
$files | ForEach-Object {
    $file = $_.Trim()
    if ($file) {
        $fullUrl = $baseUrl + $file
        $destinationPath = Join-Path $logsFolder $file
        Write-Host "Downloading $file from $fullUrl..."
        try {
            Invoke-WebRequest -Uri $fullUrl -OutFile $destinationPath -ErrorAction Stop
            Write-Host "Downloaded $file successfully!"
        }
        catch {
            Write-Host "Failed to download $file!"
            Write-Host $_.Exception.Message
        }
    }
}
#check if report dir exists
$reportDir = Join-Path $PWD "report" 

$reportDir | Where-Object { -not (Test-Path $_) } | ForEach-Object {
    New-Item -ItemType Directory -Path $_ | Out-Null
}
$monthStats = @()

$monthStats = Get-ChildItem -Path $logsFolder -File | Sort-Object Name | ForEach-Object {
    $lines = Get-Content $_.FullName
    $firstNonEmpty = $lines | Where-Object { $_.Trim() -ne "" } | Select-Object -First 1
    if ($firstNonEmpty) {
        $fields = $firstNonEmpty -split ","
        if ($fields.Count -gt 0) {
            $dateString = $fields[0].Trim()
            $year, $month, $null = $dateString -split "-"
        }
        else {
            $month = "unknown"
            $year = "unknown"
        }
    }
    else {
        $month = "unknown"
        $year = "unknown"
    }

    $infoCount = $lines | Where-Object { ($_ -split ",")[1].Trim().ToLower() -eq "info" }    | Measure-Object | Select-Object -ExpandProperty Count
    $warningCount = $lines | Where-Object { ($_ -split ",")[1].Trim().ToLower() -eq "warning" } | Measure-Object | Select-Object -ExpandProperty Count
    $errorCount = $lines | Where-Object { ($_ -split ",")[1].Trim().ToLower() -eq "error" }   | Measure-Object | Select-Object -ExpandProperty Count

    [PSCustomObject]@{
        Month   = $month
        Year    = $year
        Info    = $infoCount
        Warning = $warningCount
        Error   = $errorCount
    }
}
#counting logs using pipleine instead of foreach for better readability and performance
$infoCount = $lines | Where-Object { ($_ -split ",")[1].Trim().ToLower() -eq "info" }    | Measure-Object | Select-Object -ExpandProperty Count
$warningCount = $lines | Where-Object { ($_ -split ",")[1].Trim().ToLower() -eq "warning" } | Measure-Object | Select-Object -ExpandProperty Count
$errorCount = $lines | Where-Object { ($_ -split ",")[1].Trim().ToLower() -eq "error" }   | Measure-Object | Select-Object -ExpandProperty Count

$monthStats += [PSCustomObject]@{
    Month   = $month
    Year    = $year
    Info    = $infoCount
    Warning = $warningCount
    Error   = $errorCount
}

#percentage increase/decreasse vs previous month
for ($i = 0; $i -lt $monthStats.Count; $i++) {
    if ($i -eq 0) {
        $monthStats[$i] | Add-Member -NotePropertyName 'WarningChangePct' -NotePropertyValue $null
        $monthStats[$i] | Add-Member -NotePropertyName 'ErrorChangePct' -NotePropertyValue $null
    }else {
        $prev = $monthStats[$i - 1] 
        $curr = $monthStats[$i]
        #handle divide by zero for starting months
        if ($prev.Warning -eq 0) {
            $warnPct = $null
        }else {
            $warnPct = [math]::Round((($curr.Warning - $prev.Warning) / $prev.Warning) * 100, 2)
        }
        if ($prev.Error -eq 0) {
            $errorPct = $null
        }else {
            $errorPct = [math]::Round((($curr.Error - $prev.Error) / $prev.Error) * 100, 2)
        }
        $curr | Add-Member -NotePropertyName 'WarningChangePct' -NotePropertyValue $warnPct
        $curr | Add-Member -NotePropertyName 'ErrorChangePct' -NotePropertyValue $errorPct

    }

}
#path to JSON and HTML report
$reportPath = Join-Path $reportDir "report.json"
$htmlPath = Join-Path $reportDir "index.html"

# Write JSON first
$monthStats | ConvertTo-Json -Depth 3 | Set-Content -Path $reportPath
if (!(Test-Path $reportPath)) {
    # Create an empty array if no data was processed
    @() | ConvertTo-Json | Set-Content -Path $reportPath
}

# Read from report.json
$stats = Get-Content -Path $reportPath | ConvertFrom-Json

$html = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Monthly Log Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 2em; }
        h1 { color: #222; }
        table { border-collapse: collapse; width: 100%; margin-top: 1em; }
        th, td { padding: 0.55em; border: 1px solid #ddd; text-align: left; }
        th { background: #eeeeee; }
        tr:nth-child(even) { background: #f9f9f9; }
        .pct { color: #666; font-weight: bold; }
    </style>
</head>
<body>
    <h1>Monthly Log Stats</h1>
    <table>
        <tr>
            <th>Month</th>
            <th>Year</th>
            <th>Info Count</th>
            <th>Warning Count</th>
            <th>Error Count</th>
            <th>Warning Change %</th>
            <th>Error Change %</th>
        </tr>
"@

foreach ($stat in $stats) {
    $warnPct = $stat.WarningChangePct
    $errorPct = $stat.ErrorChangePct

    if ($null -eq $warnPct) { $warnPctDisplay = "-" } else { $warnPctDisplay = "$warnPct%" }
    if ($null -eq $errorPct) { $errorPctDisplay = "-" } else { $errorPctDisplay = "$errorPct%" }

    $html += "<tr>
        <td>$($stat.Month)</td>
        <td>$($stat.Year)</td>
        <td>$($stat.Info)</td>
        <td>$($stat.Warning)</td>
        <td>$($stat.Error)</td>
        <td class='pct'>$warnPctDisplay</td>
        <td class='pct'>$errorPctDisplay</td>
    </tr>`n"
}
$html += @"
    </table>
    <p style='margin-top:2rem;color:#888;'>Report generated on $(Get-Date -Format "yyyy-MM-dd HH:mm:ss").</p>
</body>
</html>
"@

$html | Set-Content -Path $htmlPath -Encoding UTF8
Write-Host "HTML report generated at $htmlPath"