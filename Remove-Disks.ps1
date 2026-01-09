<#
.LINK
    https://github.com/byronbayer/Powershell#remove-disksps1
#>

workflow Remove-Disks {
    param (
        [Parameter(Mandatory = $true)]
        [string[]]
        $DisksToDelete
    )   

    $AllDisks = Get-AzDisk
    
    foreach -parallel ($DiskToDelete in $DisksToDelete) {
        $current = $AllDisks | Where-Object Name -Like $DiskToDelete
        $current.Name
        Remove-AzDisk -Name $current.Name -ResourceGroupName $current.ResourceGroupName -Force -Confirm:$false
    }
}

$DisksToDelete = (Get-AzDisk | Where-Object DiskState -EQ 'Unattached').Name
#Or you could do the following
#$DisksToDelete = "disk1", "disk2", "disk3"
Remove-Disks -DisksToDelete $DisksToDelete