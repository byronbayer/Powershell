
Set-Location $PSScriptRoot
.".\Common.ps1"
Import-ExcelModule

$dateString = (Get-Date).ToString("yyyy_MM_dd_hh_mm")
$LogFileName = "Logs\$env:COMPUTERNAME-$dateString.txt"
$path = ".\File Shares.xlsx"
$xlMachines = New-Object System.Collections.ArrayList

#Read excel file in

foreach ($xlMachine in (Import-Excel -Path $path -StartRow 1)) {
    if (($xlMachine.Comment -notlike '*duplicate*')) {
        $xlMachines.Add($xlMachine) | Out-Null    
    }       
}

foreach ($machine in $xlMachines) {
    $IpAddress = ($machine."From IP Address").Trim()
    $sharefolder = ($machine."Share Name").ToString().Trim()
    $Destination = "\\$IpAddress\$sharefolder\"
    Add-LogMessage -LogFile $LogFileName -Message "------------------------------ $Destination ------------------------------"
    $File = $env:COMPUTERNAME + "TestFileToUpload.txt" 
    $Content = "This is a file to test that the upload is working"
    $Source = "$PSScriptRoot\"
    $SourceFile = $Source + $File
    $DestinationFile = $Destination + $File

    #Connect to share
    Add-LogMessage -LogFile $LogFileName -Message "Testing connection to $Destination"

    if (-Not(Test-Path $Destination)) {
        Add-LogMessage -LogFile $LogFileName -Message "FAIL - $Destination unreachable"
    }
    else {
        Add-LogMessage -LogFile $LogFileName -Message "PASS - $Destination found"        
    
        #Create file with content
        Add-LogMessage -LogFile $LogFileName -Message "Creating file "
        New-Item $File -Force
        Set-Content $File $Content
    
        #Copy/move file to share
        Add-LogMessage -LogFile $LogFileName -Message "Moving $SourceFile to $Destination"
        try {
            Move-Item -Path $SourceFile -Destination $Destination -Force -ErrorAction Stop
        }
        catch {
            Add-LogMessage -LogFile $LogFileName -Message "FAIL - Moving file to $Destination"
            Add-LogMessage -LogFile $LogFileName -Message "$_"
        
        }
        #Log output
        if (-Not(Test-Path $SourceFile)) {
            if (Test-Path $DestinationFile) {
                $readContent = Get-Content $DestinationFile
                if ($readContent -eq $Content) {
                    Add-LogMessage -LogFile $LogFileName -Message "PASS - $File moved to $Destination"        
                }
                else {
                    Add-LogMessage -LogFile $LogFileName -Message "FAIL - $File not moved to $Destination"
                    
                }
            }    
        }
        #Move file back
        Add-LogMessage -LogFile $LogFileName -Message "Moving file from $DestinationFile to $Source"
        Move-Item -Path $DestinationFile -Destination $Source -Force

        if (-Not(Test-Path $DestinationFile)) {
            if (Test-Path $SourceFile) {
                $readContent = Get-Content $SourceFile
                if ($readContent -eq $Content) {
                    Add-LogMessage -LogFile $LogFileName -Message "PASS - $File moved to $SourceFile"
        
                }
                else {
                    Add-LogMessage -LogFile $LogFileName -Message "FAIL - $File not moved to $SourceFile"
                    
                }
            }    
        }

        #Delete file
        Add-LogMessage -LogFile $LogFileName -Message "Removing temp file"
        Remove-Item $SourceFile -Force

        Add-LogMessage -LogFile $LogFileName -Message " "
    }    
}