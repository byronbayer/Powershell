# PowerShell Scripts Collection

A comprehensive collection of Azure and PowerShell utility scripts for resource management, automation, and administration tasks.

## Table of Contents

- [Azure Service Bus](#azure-service-bus)
- [Azure Resource Management](#azure-resource-management)
- [Azure Web Apps & SSL](#azure-web-apps--ssl)
- [Virtual Machine Management](#virtual-machine-management)
- [Azure Active Directory Management](#azure-active-directory-management)
- [Resource Cleanup](#resource-cleanup)
- [Tagging & Organization](#tagging--organization)
- [Development Tools](#development-tools)
- [Git & Repository Management](#git--repository-management)
- [Utility Scripts](#utility-scripts)
- [Project Folders](#project-folders)

---

## Azure Service Bus

### CallServiceBus.ps1

Comprehensive Azure Service Bus management script providing functions to create infrastructure and send messages with SAS token authentication.

**Functions:**

- `New-AzServiceBus` - Creates resource group, namespace, and queue
- `New-AzServiceBusSasToken` - Generates SAS authentication tokens
- `Send-AzServiceBusMessage` - Sends messages to Service Bus queue

**Key Features:**

- Automatic Service Bus namespace and queue creation
- SAS token generation with configurable expiry
- Message sending with custom properties
- Error handling and validation

```powershell
# Create Service Bus infrastructure
New-AzServiceBus -ResourceGroup "MyResourceGroup" `
    -Location "UK South" `
    -NamespaceName "MyNameSpaceUnique001" `
    -QueueName "MyQueue" `
    -PolicyName "RootManageSharedAccessKey"

# Send a message
Send-AzServiceBusMessage -ResourceGroupName "MyResourceGroup" `
    -NamespaceName "MyNameSpaceUnique001" `
    -QueueName "MyQueue"
```

Instructions: [Calling Azure Service Bus from PowerShell with SAS Authentication Token](https://medium.com/@byronbayer/calling-azure-service-bus-from-powershell-with-sas-authentication-token-eabf828398c8)

---

## Azure Resource Management

### GetAzureApiVersions.ps1

Advanced Azure API version discovery tool with filtering and template generation capabilities.

**Function:** `Get-AzApiVersions`

**Parameters:**

- `-ProviderNamespace` - Specific provider (e.g., 'Microsoft.Storage')
- `-ResourceTypeName` - Specific resource type (e.g., 'storageAccounts')
- `-IncludeLocations` - Show available locations
- `-IncludeVersions` - Show API versions
- `-OutputLocationsForArmTemplate` - Generate ARM template allowedValues
- `-OutputLocationsForBicep` - Generate Bicep allowed values

```powershell
# Get all versions and locations for storage accounts
Get-AzApiVersions -ProviderNamespace 'Microsoft.Storage' -ResourceTypeName 'storageAccounts' -IncludeLocations -IncludeVersions

# Generate ARM template location constraints
Get-AzApiVersions -ProviderNamespace 'Microsoft.Storage' -ResourceTypeName 'storageAccounts' -OutputLocationsForArmTemplate

# Generate Bicep location constraints
Get-AzApiVersions -ProviderNamespace 'Microsoft.Storage' -ResourceTypeName 'storageAccounts' -OutputLocationsForBicep
```

### RegisterProviders.ps1

Intelligent resource provider registration that only registers unregistered providers.

**Function:** `Register-ResourceProviders`

```powershell
$resourceProviders = @("microsoft.documentdb", "microsoft.insights", "microsoft.servicebus", "microsoft.sql", "microsoft.storage", "microsoft.web", "Microsoft.DataFactory", "Microsoft.AAD")
Register-ResourceProviders -resourceProviders $resourceProviders
```

### Remove Deployments greater then x days.ps1

Cross-subscription deployment cleanup with filtering and reporting capabilities.

**Function:** `Remove-OldDeployments`

**Parameters:**

- `-Days` - Age threshold (0 = all deployments)
- `-ShowOnlyCounts` - Report mode only
- `-ShowAllResourceGroups` - Include groups with zero deployments

```powershell
# Remove deployments older than 30 days (preview mode)
Remove-OldDeployments -Days 30 -ShowOnlyCounts $true -WhatIf

# Remove all deployments across all subscriptions
Remove-OldDeployments -Days 0 -ShowOnlyCounts $false
```

---

## Azure Web Apps & SSL

### Get-WebApp-SSLCert-Details.ps1

Retrieves Azure Web App and Azure Certificate Details. Helps to find out which Web Apps are enabled for TLS 1.0 or 1.1 so they can be moved to 1.2. Also provides information about HttpsOnly settings, Tags, Certificate Thumbprint and Expiry dates. Generates CSV, XML, and JSON output files.

Key features:

- Identifies TLS version configurations
- Checks HttpsOnly enablement
- Retrieves certificate details and expiry dates
- Exports data in multiple formats (CSV, XML, JSON)

---

## Virtual Machine Management

### GetVmDetails.ps1

Retrieves detailed information about all virtual machines across all subscriptions including VM size, OS type, network configuration, and provisioning state.

Output includes:

- Resource group and location
- VM size and OS type
- Network interface and VNET/Subnet details
- Provisioning state and availability zones

### ShutDownVms.ps1

Shuts all the VMs down in a subscription.

```powershell
Stop-Machines
```

### StartVmsInOrder/StartVms.ps1

Starts certain VMs in a particular order either starting up all together or preserving the startup order in the array passed in.

```powershell
$MachineNames = "jf-vm-002", "jf-vm-001"
Start-Machines -MachineNames $MachineNames -PreserveOrder $true
```

---

## Azure Active Directory Management

### Remove-AADAppRegistrationsWithPattern.ps1

Bulk Azure AD application registration cleanup tool with pattern-based filtering.

**Function:** `Remove-AppRegistrationsWithPattern`

**Parameters:**

- `-AppRegistrations` - Array of patterns (supports wildcards)
- `-TenantId` - Azure AD tenant ID
- `-AadUsername` - Admin username
- `-AadPassword` - Secure string password

**Features:**

- Wildcard pattern matching
- Automatic AzureAD module installation
- Tenant verification
- Bulk deletion with confirmation

```powershell
$AppRegistrations = "*api1*", "webapp*", "test-app-*"
$AadUsername = "admin@domain.com"
$AadPassword = ConvertTo-SecureString 'SecurePassword' -AsPlainText -Force
$TenantId = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"

Remove-AppRegistrationsWithPattern -AppRegistrations $AppRegistrations -AadUsername $AadUsername -AadPassword $AadPassword -TenantId $TenantId
```

---

## Resource Cleanup

### Remove-DefinedFilesFolderLocation.ps1

Will delete any files that are defined in the include and will not delete any files in the exclude. Either fill the include or the exclude, but not both. Exclude takes precedence. This is great for cleaning up a development directory.

```powershell
$include = @("*ncrunch*", "*.suo", "*.user", "*.userosscache", "*.sln.docstates", "*ncrunch*", ".vs", "bin", "obj", "build")
$exclude = @()
Remove-DefinedFilesFolderLocation -FolderLocation "C:\Dev\" -Include $include -Exclude $exclude -WhatIf
```

### Remove-Disks.ps1

Removes any disks in the list passed in.

```powershell
$DisksToDelete = (Get-AzDisk | Where-Object DiskState -EQ 'Unattached').Name
#Or you could do the following
$DisksToDelete = "disk1", "disk2", "disk3"
Remove-Disks -DisksToDelete $DisksToDelete
```

### Remove-Nics.ps1

Removes any NIC in the list passed in.

```powershell
$NICsToDelete = "nic1", "nic2", "nic3"
Remove-Nics -NICsToDelete $NICsToDelete
```

### Remove-ResourceGroupsAsyncWithPattern.ps1

Deletes all resource groups specified in the input array and stops any resources that are in the resource groups such as Azure Data Factory.
A confirmation prompt confirms the resource groups you are deleting first before any resource group is deleted.

```powershell
#Create some resource groups
for ($i = 1; $i -lt 10; $i++) {
    New-AzResourceGroup -Name "my-rg-00$i" -Location 'UK South' -Confirm:$false -Force | Out-Null
    New-AzResourceGroup -Name "test-rg-00$i" -Location 'UK South' -Confirm:$false -Force | Out-Null
}

$ResourceGroupNamePatterns = "my*", "test*"
Remove-ResourcegroupsAsync -ResourceGroupNames $ResourceGroupNamePatterns
```

### Scale SSIS IR Instance.ps1

Changes the scale and location of an SQL Server Integration Service Integration runtime instance.

```powershell
Update-SSISIR -subscription $subscription -resourceGroupName -nodeSize $nodeSize -location $location
```

---

## Tagging & Organization

### TagResourceGroupsFromResources.ps1

Will get all the tags on resources within a resource group and apply them to the Resource group where the resource group has no tags.

```powershell
Add-TagsToResourceGroupFromResources
```

### TagResourcesFromResourceGroup.ps1

Will apply tags to resources from the parent resource group.

```powershell
Add-TagsToResourcesFromResourceGroups
```

### RemoveAllTagsForResourceGroup.ps1

Removes all tags from a resource group and optionally from all resources within that resource group.

```powershell
Remove-AllTags -ResourceGroup "MyResourceGroup" -IncludeResources $true
```

---

## Git & Repository Management

### git-GetLatestVersionOfAllRepositories 1.ps1

Enterprise-scale Git repository management tool for Azure DevOps organizations.

**Function:** `Get-AllRepos`

**Parameters:**

- `-connectionToken` - Azure DevOps personal access token
- `-rootFolder` - Local repository root directory
- `-organisations` - Array of Azure DevOps organizations
- `-fetchOnly` - Fetch-only mode (no pulls)
- `-IgnoreProjects` - Projects to skip

**Features:**

- Multi-organization support
- Git-enabled project detection
- Repository cloning for missing repos
- Intelligent branch handling (main/master)
- Fetch and pull operations
- Project filtering capabilities
- Error handling and retry logic

```powershell
Get-AllRepos -connectionToken "your-pat-token" `
    -rootFolder "C:\Dev" `
    -organisations @("MyOrg1", "MyOrg2") `
    -IgnoreProjects @("archived-proj1", "legacy-proj2") `
    -fetchOnly
```

---

## Development Tools

### Switch-AzureRmWithAz.ps1

Replaces the AzureRm PowerShell modules with the new Az modules. More information can be found [here](https://docs.microsoft.com/en-us/powershell/azure/new-azureps-module-az?view=azps-2.6.0).

```powershell
Switch-AzureRmWithAz
```

### update-terraform.ps1

Comprehensive Terraform installation and update management utility with flexible deployment options.

**Function:** `Update-Terraform`

**Parameters:**

- `-InstallPath` - Custom installation directory (defaults to `$env:ProgramFiles\Terraform`)
- `-Force` - Forces reinstallation even if already up-to-date

**Key Features:**

- **Smart Detection**: Automatically detects existing Terraform installations
- **Fresh Installation**: Installs Terraform if not present with custom path support
- **Version Management**: Compares current vs latest versions from HashiCorp releases
- **Architecture Support**: Supports AMD64, ARM64, and x86 architectures
- **PATH Management**: Automatically updates system or user PATH variables
- **Admin Fallback**: Tries machine PATH first, falls back to user PATH if needed
- **Verification**: Confirms successful installation with version check
- **Color-coded Output**: Enhanced user experience with status indicators

**Installation Scenarios:**

```powershell
# Update existing installation or install to default location
Update-Terraform

# Install to custom location
Update-Terraform -InstallPath "C:\Tools\Terraform"

# Install to portable tools directory
Update-Terraform -InstallPath "D:\PortableApps\Terraform"

# Force reinstallation (useful for corrupted installations)
Update-Terraform -Force

# Custom path with force reinstall
Update-Terraform -InstallPath "C:\DevTools\Terraform" -Force
```

**Process Flow:**
1. Detects existing Terraform installation
2. Fetches latest version from GitHub releases
3. Downloads appropriate architecture package
4. Extracts to specified or existing location
5. Updates PATH environment variables
6. Verifies successful installation

### update-tdarr.ps1

Tdarr media server update utility with version management.

**Function:** `Update-TdarrNode`

**Parameters:**

- `-DestinationPath` - Installation directory

**Features:**

- Version comparison and update detection
- Official Tdarr versions.json integration
- Windows x64 package handling
- Local version tracking
- Automatic extraction and cleanup

```powershell
Update-TdarrNode -DestinationPath "D:\Tdarr\Tdarr_Node"
```

---

## Utility Scripts

### WriteMessage.ps1

Writes out messages with color-coded times and message formatting for better script output visibility.

```powershell
$stopwatch = [system.diagnostics.stopwatch]::StartNew()
Write-Message -stopwatch $stopwatch -message 'Testing the message'
'Doing other stuff'
Start-Sleep -Seconds 5
'Doing more stuff'
Write-Message -stopwatch $stopwatch -message 'Bit later on'
Write-Message -message "Some other stuff"
```

---

## Project Folders

### Create-AzVmsFromExcel/

Enterprise VM provisioning system using Excel-driven configuration.

**Files:**

- **Azure Virtual Machine Configuration.xlsx** - VM specification template
- **Create-AzVmsFromExcel.ps1** - Main orchestration script
- **Provisioning-Functions.ps1** - Core provisioning functions
- **parameters.json** - ARM template parameters
- **template.json** - VM deployment ARM template

**Functions in Provisioning-Functions.ps1:**

- `New-Infrastrucure` - Main orchestration function
- `Generate-Password` - Secure password generation
- `Build-TemplateParameters` - Excel to ARM parameter mapping
- `Create-ResourceGroup` - Resource group creation with validation
- `Deploy-AzResourceGroup` - ARM template deployment
- `Import-ExcelModule` - ImportExcel module management

**Features:**

- Excel-driven configuration management
- Secure password generation (prod vs dev)
- ARM template integration
- Resource group automation
- Resource provider registration
- Cross-subscription deployment support

```powershell
# Configure Excel file with VM specifications, then run:
.\Create-AzVmsFromExcel.ps1
```

### ListFoldersOnAllServers/

Remote server management and file discovery tools.

**Files:**

- **FindFilesModifiedWithinDate.ps1** - File modification discovery
- **RunPsScriptOnAllMachines.ps1** - Remote script execution
- **Servers.txt** - Server inventory (SERVERA, SERVERB)

**Features:**

- Multi-drive file system scanning
- Recent file modification detection (30-day window)
- Remote PowerShell script execution
- Automated logging with timestamps
- Server inventory management

```powershell
# Scripts run automatically using server list
# Output saved to timestamped log files
```

### StartVmsInOrder/

VM startup orchestration with dependency management.

**File:** **StartVms.ps1**

**Function:** `Start-Machines` (PowerShell Workflow)

**Parameters:**

- `-MachineNames` - Array of VM names
- `-PreserveOrder` - Sequential vs parallel startup

**Features:**

- Sequential dependency-aware startup
- Parallel startup for independent VMs
- Automatic resource group resolution
- PowerShell Workflow parallelization

```powershell
# Sequential startup (dependencies)
$MachineNames = "dc-vm-001", "app-vm-001", "web-vm-001"
Start-Machines -MachineNames $MachineNames -PreserveOrder $true

# Parallel startup (independent VMs)
$MachineNames = "worker-vm-001", "worker-vm-002", "worker-vm-003"
Start-Machines -MachineNames $MachineNames -PreserveOrder $false
```

### TestFilesShares/

File share connectivity and permissions testing framework.

**Files:**

- **TestFileShares.ps1** - Main testing logic
- **Start.ps1** - Azure Files integration and environment setup
- **Common.ps1** - Shared utility functions
- **File Shares.xlsx** - Test configuration matrix

**Functions in Common.ps1:**

- `Import-ExcelModule` - ImportExcel module management
- `Add-LogMessage` - Centralized logging utility

**Features:**

- Excel-driven test configuration
- Azure Files integration with cmdkey authentication
- File upload/download testing
- Connectivity validation
- Permission testing
- Comprehensive logging
- Duplicate test filtering
- Network share mounting

**Test Process:**

1. Mount Azure Files share
2. Read test configuration from Excel
3. Test connectivity to each share
4. Perform file upload/download cycles
5. Validate file integrity
6. Generate detailed logs

```powershell
# Configure File Shares.xlsx with test targets, then:
.\Start.ps1
```

---

## Getting Started

### Prerequisites

- **PowerShell 5.1 or later** (PowerShell 7+ recommended)
- **Azure PowerShell modules (Az.*)**

  ```powershell
  Install-Module -Name Az -AllowClobber -Scope CurrentUser
  ```

- **Azure authentication**

  ```powershell
  Connect-AzAccount
  ```

- **ImportExcel module** (for Excel-based scripts)

  ```powershell
  Install-Module -Name ImportExcel -Scope CurrentUser
  ```

### Common Setup Steps

1. **Azure Connection:**

   ```powershell
   Connect-AzAccount
   Set-AzContext -SubscriptionId "your-subscription-id"
   ```

2. **Execution Policy (if needed):**

   ```powershell
   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
   ```

3. **Module Installation:**

   ```powershell
   # Core Azure modules
   Install-Module Az -AllowClobber -Scope CurrentUser
   
   # Excel integration
   Install-Module ImportExcel -Scope CurrentUser
   
   # Legacy Azure AD (for specific scripts)
   Install-Module AzureAD -Scope CurrentUser
   ```

### Best Practices

- **Always use `-WhatIf`** parameter when available for preview mode
- **Review and customize variables** before running scripts
- **Test in development environments** before production use
- **Monitor Azure costs** when creating resources
- **Use resource locks** to protect critical resources
- **Implement proper error handling** in custom scripts

### Security Considerations

- **Store credentials securely** using Azure Key Vault or secure strings
- **Use least-privilege access** principles
- **Enable logging and auditing** for administrative actions
- **Regularly review and rotate** access keys and passwords
- **Use Azure AD integration** where possible instead of service accounts

## Contributing

When adding new scripts:

1. **Follow PowerShell best practices** (approved verbs, parameter validation)
2. **Include comprehensive error handling**
3. **Add parameter sets and help documentation**
4. **Support `-WhatIf` and `-Confirm` where applicable**
5. **Include usage examples and parameter descriptions**
6. **Test across multiple Azure subscriptions/tenants**
7. **Document dependencies and prerequisites**
