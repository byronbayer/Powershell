Clear-Host

'Applying tags to empty resources'
$groups = Get-AzResourceGroup

foreach ($g in $groups) {
    if ($null -ne $g.Tags) {
        '----------------------   ' + $g.ResourceGroupName + '   ----------------------------'
        $resources = Get-AzResource -ResourceGroupName $g.ResourceGroupName
        foreach ($r in $resources) {
            '   ---   ' + $r.Name + '   ---   '
            $resourcetags = (Get-AzResource -ResourceId $r.ResourceId).Tags

            if ($resourcetags) {
                foreach ($key in $g.Tags.Keys) {
                    if (-not($resourcetags.ContainsKey($key))) {
                        'Resource does not contain ' + $key
                        $resourcetags.Add($key, $group.Tags[$key])
                    }
                }
                'Tags already on resource.  Adding resource group tags to resource'
                $resourcetags
                Set-AzResource -Tag $resourcetags -ResourceId $r.ResourceId -Force
            }
            else {
                'No tags found on resource. Adding resource group tags to resource '
                Set-AzResource -Tag $group.Tags -ResourceId $r.ResourceId -Force
            }
        }
    }
}

