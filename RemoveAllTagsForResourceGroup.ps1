function Remove-AllTags {
    param (
        [Parameter(Mandatory = $false)]
        [string]
        $ResourceGroup,
        
        [Parameter(Mandatory = $false)]
        [bool]
        $IncludeResources = $false
    )
    $group = Get-AzResourceGroup -Name $ResourceGroup
    $EmptyTags = @{ }
    
    if ($null -ne $group.Tags) {
        Set-AzResourceGroup -Tag $EmptyTags -ResourceId $group.ResourceId
    }
    if ($IncludeResources) {
            
        
        $resources = Get-AzResource -ResourceGroupName $group.ResourceGroupName
        foreach ($r in $resources) {
            $resourcetags = (Get-AzResource -ResourceId $r.ResourceId).Tags
            if ($resourcetags) {            
                Set-AzResource -Tag $EmptyTags -ResourceId $r.ResourceId -Force
            }       
        }
    }
}

$ResourceGroup = "MyResourceGroup"
Remove-AllTags -ResourceGroup $ResourceGroup -IncludeResources $true