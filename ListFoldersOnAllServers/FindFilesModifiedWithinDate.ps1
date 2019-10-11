$Drives = Get-WmiObject Win32_LogicalDisk | Where-Object { $_.DriveType -eq 3 }
foreach ($Drive in $Drives) {
    $currentDrive = $Drive.DeviceId + "\"
    
    Get-ChildItem -Path $currentDrive -Recurse -ErrorAction Continue | `
            Where-Object { $_.LastWriteTime -gt (Get-Date).AddDays(-30) } | `
            Select-Object Directory -Unique
}