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
        $ResourceGroupNames
               
    )
    $allResourceGroups = Get-AzResourceGroup
    foreach -parallel ($ResoucesGroupName in $ResourceGroupNames) {
        "Current Resouces Group Name: $ResoucesGroupName"
        $resourceGroups = $allResourceGroups | Where-Object ResourceGroupName -Like $ResoucesGroupName
        foreach -parallel ($resourceGroup in $resourceGroups) {
            $ResourceGroupName = $resourceGroup.ResourceGroupName        
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

function Remove-ResourceGroups {
    param(
        #An array of resource group patterns
        [Parameter(Mandatory = $true)]
        [string[]]
        $ResourceGroupNames
               
    )
    $allResourceGroups = Get-AzResourceGroup
    $collection = { $ResourceGroupNames }.Invoke()
 
    foreach ($ResoucesGroupName in $ResourceGroupNames) {
        $collection.Remove($ResoucesGroupName)
        $collection.Add(($allResourceGroups | Where-Object ResourceGroupName -Like $ResoucesGroupName).ResourceGroupName)
    }
    
    Write-Host "Resouce Groups to be deleted:"
    Write-Host "####################################"
    $collection
    Write-Host "####################################"

    $confirmation = Read-Host "Are you Sure You Want To delete the above resouce groups (y/n)?"
    if ($confirmation -eq 'y') {
        Remove-ResourcegroupsInParralell -ResourceGroupNames $ResourceGroupNames
    }
    else {
        Write-Host "Resource groups not deleted"
    }
}

Login-AzAccount

# for ($i = 1; $i -lt 10; $i++) {
#     New-AzResourceGroup -Name "my-rg-00$i" -Location 'UK South' -Confirm:$false -Force
#     New-AzResourceGroup -Name "test-rg-00$i" -Location 'UK South' -Confirm:$false -Force    
# }

$ResourceGroupNames = "my*", "test*" 
Remove-Resourcegroups -ResourceGroupNames $ResourceGroupNames
