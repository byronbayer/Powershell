workflow Stop-Machines {
    
    $machines = Get-AzVM
    foreach -parallel ($machine in $machines ) {
        Stop-AzVM -Id $machine.Id -Force -Confirm:$false    
    }
}

