<#
    .SYNOPSIS
        Gets the versions for the Azure resource providers 
    .DESCRIPTION
        Long description
    .EXAMPLE
        PS C:\> Get-AzApiVersions
        Gets all the Azure Resouce Providers with locations adn versions
    .EXAMPLE
        PS C:\> Get-AzApiVersions -ProviderNamespace 'Microsoft.Storage' -ResourceTypeName 'storageAccounts'
        Gets all versions and locations for Microsoft.Storage/storageAccounts
    .EXAMPLE
        PS C:\> Get-AzApiVersions -ProviderNamespace 'Microsoft.Storage' -ResourceTypeName 'storageAccounts' -IncludeLocations $false
        Gets all versions and excludes locations for Microsoft.Storage/storageAccounts
    .EXAMPLE
        PS C:\> Get-AzApiVersions -ProviderNamespace 'Microsoft.Storage' -ResourceTypeName 'storageAccounts' -IncludeVersions $false
        Gets all locations and excludes versions for Microsoft.Storage/storageAccounts
    .EXAMPLE
        PS C:\> Get-AzApiVersions -ProviderNamespace 'Microsoft.Storage' -ResourceTypeName 'storageAccounts' -OutputLocationsForArmTemplate $true
        Gets all versions and locations for Microsoft.Storage/storageAccounts and adds a string of allowedValues for locations that can be coppied to an ARM template
    .EXAMPLE
        PS C:\> Get-AzApiVersions -ProviderNamespace 'Microsoft.Storage' -ResourceTypeName 'storageAccounts' -OutputLocationsForBicep $true
        Gets all versions and locations for Microsoft.Storage/storageAccounts and adds a string of allowedValues for locations that can be coppied to a Bicep file
#>

#Providers can also be found at https://resources.azure.com and navigating to 'Microsoft Azure -> Providers'

function Get-AzApiVersions {
    param  (
        $ProviderNamespace = $null,    
        $ResourceTypeName = $null,
        $IncludeLocations = $true,
        $IncludeVersions = $true,
        $OutputLocationsForArmTemplate = $false,
        $OutputLocationsForBicep = $false
    )
    if ($null -eq $ProviderNamespace) {
        $resources = Get-AzResourceProvider
    }
    else {
        $resources = Get-AzResourceProvider -ProviderNamespace $ProviderNamespace
    }
    $ProviderNamespace
    $Locations = @()
    foreach ($r in $resources) {
        if ($ProviderNamespace -ne ($r).ProviderNamespace ) {
            $ProviderNamespace = ($r).ProviderNamespace
            $ProviderNamespace
        }

        if (($null -eq $ProviderNamespace) -or ($null -eq $ResourceTypeName)) {
            $resourceTypes = ($r | Where-Object ProviderNamespace -EQ $r.ProviderNamespace).ResourceTypes
        }
        else {
            $resourceTypes = ($r | Where-Object ProviderNamespace -EQ $r.ProviderNamespace).ResourceTypes | Where-Object ResourceTypeName -EQ $ResourceTypeName
        }
    
        if ($null -eq $resourceTypes) {
            continue
        }

        foreach ($rt in $resourceTypes) {
            '  ' + $rt.ResourceTypeName        
            if ($IncludeVersions) {
                '  -Versions'
                '   |'
                foreach ($version in $rt.ApiVersions) {
                    '   |-' + $version
                }
            }

            if ($IncludeLocations) {
                if ($rt.Locations.Count -gt 0) {
                    '  -Locations'
                    '   |'
                    foreach ($location in $rt.Locations) {
                        $Locations += '"' + $location + '",'
                        '   |-' + $location
                    }
                }
                else {
                    '  -Locations'
                    '   |'
                    '   |-Global' 
                }
            }
        
            if ($OutputLocationsForArmTemplate) {
                $Locations[$Locations.Count - 1] = $Locations[$Locations.Count - 1] -replace ",", ""
                ''                
                '########### ARM Start ###############'                
                '"allowedValues": [' + $locations + ']'                
                '########### ARM End ###############'
            
            }
            if ($OutputLocationsForBicep) {
                ''
                '########### Bicep Start ###############'
                '@allowed([' 
                foreach ($location in $rt.Locations) {                    
                    '  ''' + $location + ''''
                }
                '])'                
                '########### Bicep End ###############'
            }

        }
    }

}
Get-AzApiVersions -ProviderNamespace 'Microsoft.Storage' -ResourceTypeName 'storageAccounts' -OutputLocationsForArmTemplate $true -OutputLocationsForBicep $true