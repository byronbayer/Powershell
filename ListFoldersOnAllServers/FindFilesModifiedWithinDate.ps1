# $drives = Get-PsDrive -PSProvider FileSystem | Where-Object "DisplayRoot" -NotLike "\\*"
# $drives
#Get-WmiObject Win32_DiskDrive

$Drives = Get-WmiObject Win32_LogicalDisk | Where-Object { $_.DriveType -eq 3 }
#$dateString = (Get-Date).ToString("yyyy_MM_dd_HH_mm_ss")

foreach ($Drive in $Drives) {
    $currentDrive = $Drive.DeviceId + "\"
    $DriveLetter = $currentDrive -replace ":", ""
    #$LogFileName = "$env:COMPUTERNAME-$DriveLetter-$dateString.txt"
    $Files = Get-ChildItem -Path $currentDrive -Recurse -ErrorAction Continue | `
            Where-Object { $_.LastWriteTime -gt (Get-Date).AddDays(-1) } | `
            Select-Object Directory -Unique
    
    $Files
    
}