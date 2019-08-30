Function Register-ResourceProviders {
<#
.SYNOPSIS
    Registers an array of resources on the Azure Subscription
.DESCRIPTION
    You can get a list of all resouces and their state by calling
    Get-AzResourceProvider -ListAvailable | Select-Object ProviderNamespace, RegistrationState

.EXAMPLE
    PS C:\> <example usage>
    Explanation of what the example does
.INPUTS
    Inputs (if any)
.OUTPUTS
    Output (if any)
.NOTES
    General notes
#>
    param(
        [Parameter(Mandatory = $true)]
        [string[]]
        $resourceProviders
    )
    if ($resourceProviders.length) {
        $AzResourceProviders = Get-AzResourceProvider
        Write-Host "Registering unregistered providers"
        foreach ($resourceProvider in $resourceProviders) {
            if ( -Not ($AzResourceProviders | Where-Object ProviderNamespace -EQ $resourceProvider)) {            
                Write-Host "Registering resource provider '$resourceProvider'";
                Register-AzResourceProvider -ProviderNamespace $resourceProvider -ErrorAction Continue
            }
            else{
                Write-Host "Resource provider '$resourceProvider' already registered";
            }
        }
    }
}
$resourceProviders = @("microsoft.documentdb", "microsoft.insights", "microsoft.servicebus", "microsoft.sql", "microsoft.storage", "microsoft.web", "Microsoft.DataFactory", "Microsoft.AAD");
Register-ResourceProviders -resourceProviders $resourceProviders