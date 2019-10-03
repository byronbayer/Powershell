$PSVersionTable
$AzureStorageName = "xxx.file.core.windows.net"
$User = "Azure\user"
$Password = ""

Test-NetConnection -ComputerName $AzureStorageName -Port 445
## Save the password so the drive will persist on reboot
Invoke-Expression -Command "cmdkey /add:$AzureStorageName /user:$User /pass:$Password"
## Mount the drive
New-PSDrive -Name Y -PSProvider FileSystem -Root "\\$AzureStorageName\media"

Set-Location "Y:\TestFilesShares"
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force -Confirm:$false

Copy-Item -Path "\\$AzureStorageName\media\TestFilesShares\PSModules\nuget\" `
-Destination "C:\Program Files\PackageManagement\ProviderAssemblies\" -Recurse -Force -Confirm:$false

Register-PSRepository -SourceLocation "\\$AzureStorageName\media\TestFilesShares\" -Name PSModules
Install-Module ImportExcel -Force -Confirm:$false

.\TestFileShares.ps1