<#
.LINK
    https://github.com/byronbayer/Powershell#getazureapiversionsps1
#>

function Get-AzApiVersions {
    <#
    .SYNOPSIS
    Gets the versions for the Azure resource providers 

    .DESCRIPTION
    Providers can also be found at https://resources.azure.com and navigating to 'Microsoft Azure -> Providers'

    .EXAMPLE
    PS C:\> Get-AzApiVersions
    Gets all the Azure Resouce Providers

    .EXAMPLE
    PS C:\> Get-AzApiVersions -ProviderNamespace 'Microsoft.Storage' -ResourceTypeName 'storageAccounts'
    Gets all versions and locations for Microsoft.Storage/storageAccounts

    .EXAMPLE
    PS C:\> Get-AzApiVersions -ProviderNamespace 'Microsoft.Storage' -ResourceTypeName 'storageAccounts' -IncludeLocations
    Gets all versions and excludes locations for Microsoft.Storage/storageAccounts

    .EXAMPLE
    PS C:\> Get-AzApiVersions -ProviderNamespace 'Microsoft.Storage' -ResourceTypeName 'storageAccounts' -IncludeVersions
    Gets all locations and excludes versions for Microsoft.Storage/storageAccounts

    .EXAMPLE
    PS C:\> Get-AzApiVersions -ProviderNamespace 'Microsoft.Storage' -ResourceTypeName 'storageAccounts' -OutputLocationsForArmTemplate
    Gets all versions and locations for Microsoft.Storage/storageAccounts and adds a string of allowedValues for locations that can be coppied to an ARM template

    .EXAMPLE
    PS C:\> Get-AzApiVersions -ProviderNamespace 'Microsoft.Storage' -ResourceTypeName 'storageAccounts' -OutputLocationsForBicep
    Gets all versions and locations for Microsoft.Storage/storageAccounts and adds a string of allowedValues for locations that can be coppied to a Bicep file
    #>
    
    param  (
        [Parameter()]
        [string]
        $ProviderNamespace,
        [Parameter()]
        [string]
        $ResourceTypeName,        
        [Parameter()]
        [switch]
        $IncludeLocations,
        [Parameter()]
        [switch]
        $IncludeVersions,
        [Parameter()]
        [switch]
        $OutputLocationsForArmTemplate,
        [Parameter()]
        [switch]
        $OutputLocationsForBicep
    )
    if ("" -eq $ProviderNamespace) {
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

        if (("" -eq $ProviderNamespace) -or ("" -eq $ResourceTypeName)) {
            $resourceTypes = ($r | Where-Object ProviderNamespace -EQ $r.ProviderNamespace).ResourceTypes
        }
        else {
            $resourceTypes = ($r | Where-Object ProviderNamespace -EQ $r.ProviderNamespace).ResourceTypes | Where-Object ResourceTypeName -EQ $ResourceTypeName
        }
    
        if ("" -eq $resourceTypes) {
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

Get-AzApiVersions -ProviderNamespace 'Microsoft.Storage' -ResourceTypeName 'storageAccounts' -IncludeLocations -IncludeVersions -OutputLocationsForArmTemplate -OutputLocationsForBicep
