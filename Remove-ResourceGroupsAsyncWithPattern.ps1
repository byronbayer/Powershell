workflow Remove-ResourcegroupsInParralell {
    <#
    .SYNOPSIS
        Will remove resource groups in in the patterns passed in a parallel execution

    .DESCRIPTION
        Pass in an array of resouce groups 
        # Pattern array of the resouce groups that you want deleted
        # e.g: Resouce group names: rg001_one, rg001_two, rg002_one, rg002_two, rg003_one, rg003_two,
        #Pattern to pass in to delete just 1 and 3: "rg001*", "rg003*"

    .EXAMPLE
        $ResoucesGroupNames = "rg001*", "rg010*"
        Remove-Resourcegroups -ResourceGroupNames $ResoucesGroupNames    
    .LINK
        https://github.com/byronbayer/Powershell

    .NOTES
       Will remove resource groups in in the patterns passed in a parallel execution
    #>
    param(
        #An array of resource group patterns
        [Parameter(Mandatory = $true)]
        [string[]]
        $ResourceGroupNames,
        # Parameter help description
        [Parameter(Mandatory = $false)]
        [bool]
        $RemoveLocks = $false
               
    )
    $allResourceGroups = Get-AzResourceGroup
    foreach -parallel ($ResoucesGroupName in $ResourceGroupNames) {
        "Current Resouces Group Name: $ResoucesGroupName"
        $resourceGroups = $allResourceGroups | Where-Object ResourceGroupName -Like $ResoucesGroupName
        foreach -parallel ($resourceGroup in $resourceGroups) {
            $ResourceGroupName = $resourceGroup.ResourceGroupName
            
            if ($RemoveLocks) {
                'Removing any Locks from resources in ' + $ResourceGroupName
                Get-AzResourceLock | Where-Object { $_.ResourceGroupName -eq $ResourceGroupName } | Remove-AzResourceLock -Force
                
            }

            $df = Get-AzDataFactoryV2 -ResourceGroupName $ResourceGroupName
            if ($df) {
                $ir = Get-AzDataFactoryV2IntegrationRuntime -ResourceGroupName $ResourceGroupName -DataFactoryName $df.DataFactoryName
                if ($ir) {
                    if ($ir.State -eq 'Started') {
                        'Stopping IR' + $ir.Id
                        Stop-AzDataFactoryV2IntegrationRuntime -ResourceId $ir.Id -Force -Confirm:$false
                    }
                }
            }
                        
            'Removing resource group ' + $ResourceGroupName
            Remove-AzResourceGroup -Id $resourceGroup.ResourceId -Force -Confirm:$false
        }
    }
}

function Remove-ResourceGroupsAsync {
    param(
        #An array of resource group patterns
        [Parameter(Mandatory = $true)]
        [string[]]
        $ResourceGroupNamePatterns,
        [Parameter(Mandatory = $false)]
        [bool]
        $RemoveLocks = $false
    )
    $allResourceGroups = Get-AzResourceGroup    
    $collection = { $ResourceGroupNamePatterns }.Invoke()
 
    foreach ($ResoucesGroupName in $ResourceGroupNamePatterns) {
        $collection.Remove($ResoucesGroupName)
        $collection.Add(($allResourceGroups | Where-Object ResourceGroupName -Like $ResoucesGroupName).ResourceGroupName)
    }
    
    Write-Host "Resouce Groups to be deleted:"
    Write-Host "####################################"
    $collection
    Write-Host "####################################"

    $confirmation = Read-Host "Are you Sure You Want To delete the above resouce groups (y/n)?"
    if ($confirmation -eq 'y') {
        Remove-ResourcegroupsInParralell -ResourceGroupNames $ResourceGroupNamePatterns -RemoveLocks $RemoveLocks
    }
    else {
        Write-Host "Resource groups not deleted"
    }
}

function Add-CurrentIpToServerFirewall {
    param(
        [Parameter(Mandatory = $true)]
        [string] $ResourceGroupName,
        [Parameter(Mandatory = $true)]
        [string] $ServerName
    )

    $ip = Invoke-RestMethod http://ipinfo.io/json | Select-Object -exp ip
    $firewallRuleName = "AllowIpForDeployment"
    New-AzSqlServerFirewallRule -ResourceGroupName $ResourceGroupName `
        -ServerName $ServerName `
        -FirewallRuleName $firewallRuleName `
        -StartIpAddress $ip -EndIpAddress $ip -Verbose

}


# ################################ Set up test data ############################################

# $resourceGroupeName = 'my-rg-001'
# $location = 'UK South'

# for ($i = 1; $i -lt 10; $i++) {
#     New-AzResourceGroup -Name "my-rg-00$i" -Location $location -Confirm:$false -Force | Out-Null
#     New-AzResourceGroup -Name "test-rg-00$i" -Location $location -Confirm:$false -Force | Out-Null
# }

# $cred = $(New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList 'AdminUser', $(ConvertTo-SecureString -String 'p@$$w0rd' -AsPlainText -Force))
# $sqlServer = New-AzSqlServer -ServerName 'my-svr-001' -Location $location -ResourceGroupName $resourceGroupeName -SqlAdministratorCredentials $cred
# Add-CurrentIpToServerFirewall -ResourceGroupName $resourceGroupeName -ServerName $sqlServer.ServerName
# New-AzSqlServerFirewallRule -ResourceGroupName $resourceGroupeName -ServerName $sqlServer.ServerName -AllowAllAzureIPs

# $adf = Set-AzDataFactoryV2 -Name 'my-df-001' -Location $location -ResourceGroupName $resourceGroupeName
# $dfrt = Set-AzDataFactoryV2IntegrationRuntime -ResourceGroupName $resourceGroupeName `
#     -Name 'integrationRuntime' `
#     -Location $location `
#     -DataFactoryName $adf.DataFactoryName `
#     -CatalogServerEndpoint $sqlServer.FullyQualifiedDomainName `
#     -CatalogAdminCredential $cred `
#     -Type Managed `
#     -NodeSize 'Standard_D2_v3' `
#     -NodeCount 1 `
#     -CatalogPricingTier 'S0' `
#     -MaxParallelExecutionsPerNode 1

# ### This can take 20 minutes to provision ###
# Start-AzDataFactoryV2IntegrationRuntime -ResourceId $dfrt.Id -Force -Verbose
# $asp = New-AzAppServicePlan -Name 'my-asp-001' -Location $location -ResourceGroupName $resourceGroupeName

# New-AzResourceLock -ResourceGroupName $resourceGroupeName -LockName 'my-asp-001-lock' -LockLevel CanNotDelete -ResourceName $asp.Name -ResourceType 'Microsoft.Web/serverfarms' -Force -Confirm:$false 

##############################################################################################

# $AzCredential = $(New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList 'jay.freeman@purplebricks.com', $(ConvertTo-SecureString -String '7XZ$0*hp1cDrkVzvgXkiRMNTs' -AsPlainText -Force))
# Connect-AzAccount -Credential $AzCredential
# Select-AzSubscription 'Dev-Playground'

$ResourceGroupNamePatterns = "my*", "test*"
Remove-ResourcegroupsAsync -ResourceGroupNamePatterns $ResourceGroupNamePatterns -RemoveLocks $true
