# index file URL
$indexUrl = "https://files.singular-devops.com/challenges/01-applogs/index.txt"
#Base URL for log files
$baseUrl = "https://files.singular-devops.com/challenges/01-applogs/"
#local paths
$indexPath = "./index.txt"
$logsFolder = "./logs"

Write-Host "Starting script to download log files from index..."

#checks if logs folder exists, if not then creates it
if (!(Test-Path $logsFolder)) {
    New-Item -ItemType Directory -path $logsFolder | Out-Null
    Write-Host "Created logs folder. "
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
foreach ($file in $files) {
    $file = $file.Trim()

    if ($file -ne "") {
        $fullUrl = $baseUrl + $file
        $destinationPath = Join-Path $logsFolder $file

        Write-Host "Downloading $file from $fullUrl..."
        try {
            Invoke-WebRequest -Uri $fullUrl -Outfile $destinationPath -ErrorAction Stop
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
if (!(Test-Path $reportDir)){
    New-Item -ItemType Directory -path $reportDir | Out-Null
}
$monthStats = @()

$logfiles = Get-ChildItem -Path $logsFolder -File | Sort-Object Name

foreach ($Log in $logfiles){
    $lines = Get-Content $log.FullName
    #skips bvlank lines and gets the first line with content to extract month and year
    $firstNonEmpty = $lines | Where-Object {$_.Trim() -ne ""} | Select-Object -First 1
    if ($firstNonEmpty){
        $fields = $firstNonEmpty -split ","
        if ($fields.Count -gt 0){
            $dateString = $fields[0].Trim()
            $year, $month, $null = $dateString -split "-"
        }
        else{
            $month = "unknown"
            $year = "unknown"
        }
    }else{
        $month = "unknown"
        $year = "unknown"
    }
    
    $infoCount = 0 
    $errorCount = 0
    $warningCount = 0

    foreach ($line in $lines){
        $fields = $line -split ","
        if ($fields.Count -gt 1){
            $level = $fields[1].Trim().ToLower()
            switch ($level){
                "info" {$infoCount++}
                "warning" {$warningCount++}
                "error" {$errorCount++}
            }
        }
    }
    $monthStats += [PSCustomObject]@{
        Month = $month
        Year = $year
        Info = $infoCount
        Warning = $warningCount
        Error = $errorCount
    }
}
#percentage increase/decreasse vs previous month
for ($i=0; $i -lt $monthStats.Count; $i++){
    if ($i -eq 0){
        $monthStats[$i] | Add-Member -NotePropertyName 'WarningChangePct' -NotePropertyValue $null
        $monthStats[$i] | Add-Member -NotePropertyName 'ErrorChangePct' -NotePropertyValue $null
    }else{
        $prev = $monthStats[$i -1] 
        $curr = $monthStats[$i]
        #handle divide by zero for starting months
        if ($prev.Warning -eq 0) {
            $warnPct = $null
        }else{
            $warnPct = [math]::Round((($curr.Warning - $prev.Warning) /$prev.Warning) * 100,2)
        }
        if ($prev.Error -eq 0){
            $errorPct = $null
        }else{
            $errorPct = [math]::Round((($curr.Error - $prev.Error) / $prev.Error) *100,2)
        }
        $curr | Add-Member -NotePropertyName 'WarningChangePct' -NotePropertyValue $warnPct
        $curr | Add-Member -NotePropertyName 'ErrorChangePct' -NotePropertyValue $errorPct

    }

}
#output to JSON in ./report/report.json
$reportPath = Join-Path $reportDir "report.json"
$monthStats | ConvertTo-Json -Depth 3 | Set-Content -Path $reportPath

Write-Host "Report generated at $reportPath"