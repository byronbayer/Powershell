
$VM = Get-AzVM
$VM | Select-Object ResourceGroupName, Name, Location, `
    @{Name = "VmSize"; Expression = { $_.HardwareProfile.VmSize } }, `
    @{Name = "OSType"; Expression = { $_.StorageProfile.OSDisk.OSType } }, `
    @{Name = "NIC"; Expression = { (Get-AzNetworkInterface -ResourceId $_.NetworkProfile.networkInterfaces.Id).Name } }, `
    @{Name = "VNET"; Expression = { ((Get-AzNetworkInterface -ResourceId $_.NetworkProfile.networkInterfaces.Id).IpConfigurations[0].Subnet.Id -replace "/subnets.*", "") -replace ".*virtualNetworks/", "" } }, `
    @{Name = "SubNet"; Expression = { (Get-AzNetworkInterface -ResourceId $_.NetworkProfile.networkInterfaces.Id).IpConfigurations[0].Subnet.Id -replace ".*subnets/", "" } }, `
    ProvisioningState, `
    Zones | Format-Table