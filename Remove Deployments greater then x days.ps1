function Remove-OldDeployments {
    [cmdletbinding(SupportsShouldProcess = $true)]
    param(
        
        [Parameter(Mandatory = $false)]
        [int]
        $Days = 0,
        [Parameter(Mandatory = $false)]
        [bool]
        $ShowOnlyCounts = $false        
    )
    $totalCount = 0
    Get-AzResourceGroup | ForEach-Object {
        "Resource group: " + $_.ResourceGroupName
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
        $count
        $totalCount = $totalCount + $count
    }
    $totalCount
}
$Days = 0
Remove-OldDeployments -Days $Days -ShowOnlyCounts $true -WhatIf