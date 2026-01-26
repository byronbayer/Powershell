<#
.LINK
    https://github.com/byronbayer/Powershell#remove-deployments-greater-then-x-daysps1
#>

function Remove-OldDeployments {
    [cmdletbinding(SupportsShouldProcess = $true)]
    param(
        
        [Parameter(Mandatory = $false)]
        [int]
        $Days = 0,
        [Parameter(Mandatory = $false)]
        [bool]
        $ShowOnlyCounts = $false,
        [Parameter(Mandatory = $false)]
        [bool]
        $ShowAllResourceGroups = $false
    )
    Get-AzSubscription | ForEach-Object {
        $subscriptionName = $_.Name
        "---------------------------- $subscriptionName -----------------------------"
        Select-AzSubscription $_.SubscriptionId | Out-Null
        $totalCount = 0
        Get-AzResourceGroup | ForEach-Object {
            $count = 0
            Get-AzResourceGroupDeployment -ResourceGroupName $_.ResourceGroupName | 
            Where-Object { $_.Timestamp.Date -lt ((Get-Date).ToUniversalTime().AddDays(-$Days)) } | 
            ForEach-Object {
                if (!$ShowOnlyCounts) {
                    'Deleteing ' + $_.DeploymentName + ' ' + $_.Timestamp            
                    Remove-AzResourceGroupDeployment -Name $_.DeploymentName -ResourceGroupName $_.ResourceGroupName
                }            
                $count ++
            }
            if ($ShowAllResourceGroups -or $count -gt 0) {
                "Resource group: " + $_.ResourceGroupName
                $count
            }
            $totalCount = $totalCount + $count
        }
        "Total Count for $subscriptionName : $totalCount"
        "---------------------------------------------------"
    }
}
$Days = 0
Remove-OldDeployments -Days $Days -ShowOnlyCounts $true -ShowAllResourceGroups $false