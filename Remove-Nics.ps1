<#
.LINK
    https://github.com/byronbayer/Powershell#remove-nicsps1
#>

workflow Remove-Nics {
    param (
        [Parameter(Mandatory = $true)]
        [string[]]
        $NICsToDelete
    )   

    $AllNics = Get-AzNetworkInterface
    
    foreach -parallel ($NICToDelete in $NICsToDelete) {
        $current = $AllNics | Where-Object Name -Like $NICToDelete
        #$current
        (Get-AzNetworkInterface -Name $current.Name -ResourceGroupName $current.ResourceGroupName).Name
        Remove-AzNetworkInterface -Name $current.Name -ResourceGroupName $current.ResourceGroupName -Force -Confirm:$false
    }
}

$NICsToDelete = "nic1", "nic2", "nic3"
Remove-Nics -NICsToDelete $NICsToDelete