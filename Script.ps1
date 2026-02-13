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

Write-Host "`n============Log Analysis============"

$logfiles = Get-ChildItem -Path $logsFolder -File

foreach ($Log in $logfiles){
    Write-Host "Analysing $($Log.Name)..."
    #skips bvlank lines and gets the first line with content to extract month and year
    $lines = Get-Content $log.FullName
    $firstNonEmpty = $lines | Where-Object {$_.Trim() -ne ""} | Select-Object -First 1
    if ($firstNonEmpty){
        $fields = $firstNonEmpty -split ","
        if ($fields.Count -gt 0){
            $dateString = $fields[0].Trim()
            $year, $month, $null = $dateString -split "-"
            $monthYear = "$month/$year"
        }
        else{
            $monthYear = "unknown"
        }
    }else{
        $monthYear = "unknown"
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
    Write-Host "Month/Year: $monthYear"
    Write-Host "Information Messages: $infoCount"
    Write-Host "Warning Messages : $warningCount"
    Write-Host "Error Messages : $errorCount"
}