Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force -Confirm:$false
Invoke-Command -ComputerName (Get-Content C:\Powershell\Servers.txt) -FilePath C:\Powershell\GetModifiedFiles.ps1