workflow RemoveDisks {
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
$DisksToDelete
#Or you could do the following
#$DisksToDelete = "disk1", "disk2", "disk3"
RemoveDisks -DisksToDelete $DisksToDelete