function Remove-ResourcegroupsInParallel {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (        
        [Parameter(Mandatory = $true)]
        [string[]]
        $ResourceGroupNames,
        [Parameter(Mandatory = $false)]
        [bool]
        $RemoveLocks = $false
    )
    
    Remove-Job -State Completed
    
    foreach ($ResouceGroupName in $ResourceGroupNames) {
        Start-Job -InputObject $_ -ScriptBlock {
            #Select-AzSubscription $input.SubscriptionId
            Get-AzResourceGroup | Where-Object ResourceGroupName -Like "$($ResouceGroupName)" | Remove-AzResourceGroup -Force -Confirm:$false
        }
    }
    
    while (Get-Job -State Running) {    
    
        Get-Job | ForEach-Object {
            Receive-Job -Job $_        
        }    
        Start-Sleep 1    
    }
}

function Remove-ResourceGroupsAsync {
    [CmdletBinding(SupportsShouldProcess = $true)]
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
    foreach ($ResoucesGroupNamePattern in $ResourceGroupNamePatterns) {
        $collection.Remove($ResoucesGroupNamePattern)
        $collection.Add(($allResourceGroups | Where-Object ResourceGroupName -Like $ResoucesGroupNamePattern).ResourceGroupName)
    }
    
    Write-Host "Resource Groups to be deleted:"
    Write-Host "####################################"
    $collection
    Write-Host "####################################"

    $confirmation = Read-Host "Are you Sure You Want To delete the above resouce groups (y/n)?"
    if ($confirmation -eq 'y') {
        Remove-ResourcegroupsInParallel -ResourceGroupNames $collection[0] -RemoveLocks $RemoveLocks
    }
    else {
        Write-Host "Resource groups not deleted"
    }
}
# ################################ Set up test data ############################################
# $resourceGroupeName = 'my-rg-001'
# $location = 'UK South'
# # Create resourcegroups
# for ($i = 1; $i -lt 10; $i++) {
#     New-AzResourceGroup -Name "my-rg-00$i" -Location $location -Confirm:$false -Force | Out-Null
#     New-AzResourceGroup -Name "test-rg-00$i" -Location $location -Confirm:$false -Force | Out-Null
# }
# #Create SQL Server for ADF
# $cred = $(New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList 'AdminUser', $(ConvertTo-SecureString -String 'p@$$w0rd' -AsPlainText -Force))
# $sqlServer = New-AzSqlServer -ServerName 'my-svr-001' -Location $location -ResourceGroupName $resourceGroupeName -SqlAdministratorCredentials $cred
# #Update firewall rules 
# Add-CurrentIpToServerFirewall -ResourceGroupName $resourceGroupeName -ServerName $sqlServer.ServerName
# New-AzSqlServerFirewallRule -ResourceGroupName $resourceGroupeName -ServerName $sqlServer.ServerName -AllowAllAzureIPs
# #Create Azure Data factory
# $adf = Set-AzDataFactoryV2 -Name 'my-df-001' -Location $location -ResourceGroupName $resourceGroupeName
# #Create Azure Data factory integration runtime
# $dfrt = Set-AzDataFactoryV2IntegrationRuntime -ResourceGroupName $resourceGroupeName -Name 'integrationRuntime' `
#     -Location $location -DataFactoryName $adf.DataFactoryName -CatalogServerEndpoint $sqlServer.FullyQualifiedDomainName `
#     -CatalogAdminCredential $cred -Type Managed -NodeSize 'Standard_D2_v3'-NodeCount 1 -CatalogPricingTier 'S0' `
#     -MaxParallelExecutionsPerNode 1

# ### This can take 20 minutes to provision ###
# Start-AzDataFactoryV2IntegrationRuntime -ResourceId $dfrt.Id -Force -Verbose
# #Create an app service plan
# $asp = New-AzAppServicePlan -Name 'my-asp-001' -Location $location -ResourceGroupName $resourceGroupeName
# #Lock the App service plan to prevent it being deleted
# New-AzResourceLock -ResourceGroupName $resourceGroupeName -LockName 'my-asp-001-lock' `
#     -LockLevel CanNotDelete -ResourceName $asp.Name -ResourceType 'Microsoft.Web/serverfarms' -Force -Confirm:$false 
##############################################################################################

# Remove-ResourceGroups -SubscriptionPattern '*' -ResouceGroupPattern '*'
Set-Location $PSScriptRoot

$ResourceGroupNamePatterns = "p4f-*"
Remove-ResourcegroupsAsync -ResourceGroupNamePatterns $ResourceGroupNamePatterns -RemoveLocks $false -WhatIf