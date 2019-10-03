Set-Location $PSScriptRoot
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force -Confirm:$false
$Result = Invoke-Command -ComputerName (Get-Content .\Servers.txt) -FilePath .\FindFilesModifiedWithinDate.ps1
$dateString = (Get-Date).ToString("yyyy_MM_dd_hh_mm")
$LogFileName = "$env:COMPUTERNAME-$dateString.txt"
if (-Not( Test-Path $LogFileName)) {
    New-Item $LogFileName
}
Add-Content $LogFileName $Result