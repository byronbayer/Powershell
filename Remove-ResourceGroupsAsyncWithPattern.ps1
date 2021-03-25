workflow Remove-ResourcegroupsInParallel {
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
                Get-AzResourceLock -ResourceGroupName $ResourceGroupName | Remove-AzResourceLock -Force                
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
            Remove-AzResourceGroup -Id $resourceGroup.ResourceId -Force -Confirm:$false -AsJob
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
    foreach ($ResoucesGroupNamePattern in $ResourceGroupNamePatterns) {
        $collection.Remove($ResoucesGroupNamePattern)
        $collection.Add(($allResourceGroups | Where-Object ResourceGroupName -Like $ResoucesGroupNamePattern).ResourceGroupName)
    }
    
    Write-Host "Resouce Groups to be deleted:"
    Write-Host "####################################"
    $collection
    Write-Host "####################################"

    $confirmation = Read-Host "Are you Sure You Want To delete the above resouce groups (y/n)?"
    if ($confirmation -eq 'y') {
        Remove-ResourcegroupsInParallel -ResourceGroupNames $ResourceGroupNamePatterns -RemoveLocks $RemoveLocks
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

# How to delete all RGs that start with "my" or "test"
# $ResourceGroupNamePatterns = "my*", "test*"

# How to select all RGs except ones you want saved, e.g. "NameOfResourceGroupIWantSaved1" & "NameOfResourceGroupIWantSaved2"
# $rgs = Get-AzResourceGroup
# $names = $rgs | ForEach ResourceGroupName
# $ResourceGroupNamePatterns = $names | Where-Object { $_ –ne "NameOfResourceGroupIWantSaved1" }
# $ResourceGroupNamePatterns = $ResourceGroupNamePatterns | Where-Object { $_ –ne "NameOfResourceGroupIWantSaved2" }

Remove-ResourcegroupsAsync -ResourceGroupNamePatterns $ResourceGroupNamePatterns -RemoveLocks $true
