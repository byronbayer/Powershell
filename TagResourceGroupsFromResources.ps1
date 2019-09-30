function Add-TagsToResourceGroupFromResources {
    $groups = Get-AzResourceGroup | Where-Object { $null -eq $_.Tags }
    $resources = Get-AzResource
    foreach ($g in $groups) {
        $resourceGroupTags = $g.Tags
        '----------------------   ' + $g.ResourceGroupName + '   ----------------------------'
        foreach ($r in $resources | Where-Object { $_.ResourceGroupName -eq $g.ResourceGroupName } ) {
            '                             '
            '   ---   ' + $r.Name + '   ---   '        
            if ($r.Tags) {
                foreach ($key in $r.Tags.Keys) {
                    if ($null -eq $resourceGroupTags -or -not($resourceGroupTags.ContainsKey($key))) {
                        'Resource group does not contain ' + $key
                        $resourceGroupTags.Add($key, $g.Tags[$key])
                    }
                }
                'Adding resource tags from ' + $r.Name + 'to resource group ' + $g.ResourceGroupName
                Set-AzResourceGroup -Tag $resourcetags -ResourceId $r.ResourceId -Force
            }
            else {
                'No tags found on resource ' + $r.Name + '.'
            }
        }    
    }
}
Add-TagsToResourceGroupFromResources