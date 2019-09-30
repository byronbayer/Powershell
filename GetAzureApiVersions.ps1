<#
.SYNOPSIS
    Gets the versions for the Azure resource providers 
.DESCRIPTION
    Long description
.EXAMPLE
    PS C:\> Get-AzApiVersions
    Gets all the Azure Resouce Providers with locations adn versions
.INPUTS
    Inputs (if any)
.OUTPUTS
    Output (if any)
.NOTES
    General notes
#>

#Providers can also be found at https://resources.azure.com and navigating to 'Microsoft Azure -> Providers'

function Get-AzApiVersions {
    param  (
        $ProviderNamespace = $null,    
        $ResourceTypeName = $null,
        $IncludeLocations = $true,
        $IncludeVersions = $true,
        $OutputLocationsForArmTemplate = $false
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
            }
        
            if ($OutputLocationsForArmTemplate) {
                $Locations[$Locations.Count - 1] = $Locations[$Locations.Count - 1] -replace ",", ""            
                '"allowedValues": [' + $locations + ']'
            
            }

        }
    }

}
Get-AzApiVersions -IncludeVersions $true -IncludeLocations $false