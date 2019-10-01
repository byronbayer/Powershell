# Powershell
## CallServiceBus.ps1
Provides an easy way to place a message on a service bus queue. It also has the code to create the azure infrastructure needed
Instructions can be found here: https://medium.com/@byronbayer/calling-azure-service-bus-from-powershell-with-sas-authentication-token-eabf828398c8

## GetAzureApiVersions.ps1
Gets the API versions used with ARM templates in a structured tree. You can choose to include or exclude locations and versions

```powershell
Get-AzApiVersions -IncludeVersions $true -IncludeLocations $false
```

## RegisterProviders.ps1
Registers resource providers in the passed in array if the provider is not registered already

```powershell
$resourceProviders = @("microsoft.documentdb", "microsoft.insights", "microsoft.servicebus", "microsoft.sql", "microsoft.storage", "microsoft.web", "Microsoft.DataFactory", "Microsoft.AAD");
Register-ResourceProviders -resourceProviders $resourceProviders
```

## Remove Deployments greater then x days.ps1
Removes resource group deployments which are greater than the date specified. Specfying 0 days will delete all resource group deployments. ShowOnlyCounts parameter will only show the amount of deployments per resource group and not delete and deployments

```powershell
$Days = 30

Remove-OldDeployments -Days $Days -ShowOnlyCounts $true -WhatIf
```

## Remove-AADAppRegistrationsWithPattern.ps1

Removes the App registrations from within AAD apps list. This is very handy when you are using CI/CD to deploy your apps or apis that use AAD authenticated and the apps need to be removed from AAD and re-added registered.

``` powershell
$AppRegistrations = "*api1", "webapp*", "anotherapp"
$AadUsername = "AadUsername"
$AadPassword = ConvertTo-SecureString 'AadPassword' -AsPlainText -Force
$TenantId = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
Remove-AppRegistrationsWithPattern -AppRegistrations $AppRegistrations -AadUsername $AadUsername -AadPassword $AadPassword -TenantId $TenantId
```

## Remove-DefinedFilesFolderLocation.ps1
Will delete any files that are defined in the include and will not delete any files in the exclude. Either fill the include or the exclude, but not both. Exclude takes presedence. This is great for cleaning up a development directory
``` powershell
$include = @("*ncrunch*", "*.suo", "*.user", "*.userosscache", "*.sln.docstates", "*ncrunch*", ".vs", "bin", "obj", "build")
$exclude = @()
Remove-DefinedFilesFolderLocation -FolderLocation "C:\Dev\" -Include $include -Exclude $exclude -WhatIf
```

## Remove-Disks.ps1
Removes any disks in the list passed in
```powershell
$DisksToDelete = (Get-AzDisk | Where-Object DiskState -EQ 'Unattached').Name
#Or you could do the following
$DisksToDelete = "disk1", "disk2", "disk3"
Remove-Disks -DisksToDelete $DisksToDelete
```

## Remove-Nics.ps1
Removes any NIC in the list passed in
```powershell
$NICsToDelete = "nic1", "nic2", "nic3"
Remove-Nics -NICsToDelete $NICsToDelete
```

## DeleteResourceGroupsAsyncWithPattern.ps1
Deletes all resoure groups specified in the input array and stops any resources that are in the resource groups such as Azure Data Factory.
A confirmation confirm the resource groups you are deleting first before any resource group is deleted
```powershell
#Create some resouce groups
for ($i = 1; $i -lt 10; $i++) {
    New-AzResourceGroup -Name "my-rg-00$i" -Location 'UK South' -Confirm:$false -Force | Out-Null
    New-AzResourceGroup -Name "test-rg-00$i" -Location 'UK South' -Confirm:$false -Force | Out-Null
}

$ResourceGroupNamePatterns = "my*", "test*"
Remove-ResourcegroupsAsync -ResourceGroupNames $ResourceGroupNamePatterns
``` 

## Scale SSIS IR Instance.ps1
Changes the scale and location of an Sql Server Integration Service Integration runtime instance.
```powershell

Update-SSISIR -subscription $subscription -resourceGroupName -nodeSize $nodeSize -location $location
```

## ShutDownVms.ps1
Shuts all the VMs down in a subscription
```powershell
Stop-Machines
```

## StartVms.ps1
Starts certain VMs in a paticular order either starting up all together or preserving the startup order in the array passed in.

```powershell
$MachineNames = "jf-vm-002", "jf-vm-001"
Start-Machines -MachineNames $MachineNames -PreserveOrder $true
```

## Switch-AzureRmWithAz.ps1
Replaces the AzureRm powershell modules with the new Az modules. Moreinformation can be found here
https://docs.microsoft.com/en-us/powershell/azure/new-azureps-module-az?view=azps-2.6.0
```powershell
Switch-AzureRmWithAz
```

## TagResourceGroupsFromResources.ps1
Will get all the tags on resouces within a resource group and apply them to the Resouce group where the resource group has no tags
```powershell
Add-TagsToResourceGroupFromResources
```

## TagResourcesFromResourceGroup.ps1
Will apply tags to resources from the parent resource group.
```powershell
Add-TagsToResourcesFromResourceGroups
```

## WriteMessage.ps1
Writes out messages with colour coded times and message
```powershell
$stopwatch = [system.diagnostics.stopwatch]::StartNew()
Write-Message -stopwatch $stopwatch -message 'Testing the message'
'Doing other stuff'
Start-Sleep -Seconds 5
'Doing more stuff'
Write-Message -stopwatch $stopwatch -message 'Bit later on'
Write-Message -message "Some other stuff"
```