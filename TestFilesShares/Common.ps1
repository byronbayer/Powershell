function Import-ExcelModule {
    if ($null -eq (Get-Module ImportExcel)) {
        Install-Module ImportExcel -Force -Confirm:$false -AllowClobber
    }    
}

function Add-LogMessage {
    param (
        # Parameter help description
        [Parameter(Mandatory = $true)]
        [string]
        $LogFile,
        [Parameter(Mandatory = $true)]
        [string]
        $Message
    )
    if (-Not( Test-Path $LogFile)) {
        New-Item $LogFile
    }
    Write-Host $Message
    Add-Content $LogFile $Message
}