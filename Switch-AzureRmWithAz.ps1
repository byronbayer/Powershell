function Switch-AzureRmWithAz {
    <#
    .SYNOPSIS
        Replace AzureRm with Az
    .DESCRIPTION
        This powershell script will remove AzureRm modue and replace it with the new Az module
    .EXAMPLE
        PS C:\> Switch-AzureRmWithAz    
    .NOTES
        General notes
    #>

    $azureRmModule = Get-InstalledModule AzureRM -ErrorAction SilentlyContinue

    if ($azureRmModule) {
        Write-Host 'AzureRM module exists. Removing it'
        Uninstall-Module -Name AzureRM -AllVersions
        Write-Host 'AzureRM module removed'
    }
    else {
        Write-Host '* Congratulations * !!!! AzureRM module does not exist.'
    }
    $azModule = Get-InstalledModule Az

    if ($azModule) {
        'Updating Az module to the latest version'
        Update-Module Az
    }
    else {
        'Installing the Az module'
        Install-Module Az -Force -confirm:$false -AllowClobber
        Uninstall-AzureRm
    }
}
Switch-AzureRmWithAz