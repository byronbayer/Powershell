workflow Start-Machines {
    param (
        
        [Parameter(Mandatory = $true)]
        [string[]]
        $MachineNames,
        
        [Parameter()]
        [bool]
        $PreserveOrder
    )
    
    if ($PreserveOrder -eq $true) {
        foreach ($MachineName in $MachineNames) {
            $Machine = Get-AzVM -Name $MachineName
            Start-AzVM -ResourceGroupName $Machine.ResourceGroupName -Name $Machine.Name
            
        }
    }
    else {
        foreach -parallel ($MachineName in $MachineNames) {
            $Machine2 = Get-AzVM -Name $MachineName
            Start-AzVM -ResourceGroupName $Machine2.ResourceGroupName -Name $Machine2.Name
        }
    }
}

$MachineNames = "jf-vm-002", "jf-vm-001"
Start-Machines -MachineNames $MachineNames -PreserveOrder $false