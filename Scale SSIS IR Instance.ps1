<#
.LINK
    https://github.com/byronbayer/Powershell#scale-ssis-ir-instanceps1
#>

function Update-SSISIR {
    param(
        [Parameter(Mandatory = $True)]
        [string]
        $subscription,

        [Parameter(Mandatory = $True)]
        [string]
        $resourceGroupName,
    
        [Parameter()]
        [string]
        $nodeSize = 'Standard_D2_v3',

        [Parameter()]
        [string]
        $location
    )

    Select-AzSubscription -Subscription $subscription
    $dataFactory = Get-AzDataFactoryV2 -ResourceGroupName $resourceGroupName
    $integrationRuntime = Get-AzDataFactoryV2IntegrationRuntime -ResourceGroupName $resourceGroupName -DataFactoryName $dataFactory.DataFactoryName

    if ($null -eq $location) {
        $location = $integrationRuntime.Location
    }

    'Existing Integration runtime settings:'
    $integrationRuntime

    if ($location -eq $integrationRuntime.Location -and $nodeSize -eq $integrationRuntime.NodeSize) {
        'The existing integration runtime already has a location of ' + $location + ' and a node size of ' + $nodeSize
        'No changes made to the Integration runtime ' + $integrationRuntime.Name
        exit
    }

    'Stopping integration Runtime...'
    Stop-AzDataFactoryV2IntegrationRuntime -ResourceId $integrationRuntime.Id -Force

    'Setting integration runtime to ' + $nodeSize
    Set-AzDataFactoryV2IntegrationRuntime -ResourceGroupName $resourceGroupName `
        -DataFactoryName $dataFactory.DataFactoryName `
        -NodeSize $nodeSize `
        -Location $location `
        -Name $integrationRuntime.Name -Force

    'New values set to: '
    Get-AzDataFactoryV2IntegrationRuntime -ResourceGroupName $resourceGroupName -DataFactoryName $dataFactory.DataFactoryName

    'Starting integration Runtime...'
    Start-AzDataFactoryV2IntegrationRuntime -ResourceId $integrationRuntime.Id -Force

}


Update-SSISIR -subscription $subscription -resourceGroupName -nodeSize $nodeSize -location $location