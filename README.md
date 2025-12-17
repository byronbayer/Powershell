# PowerShell Scripts Collection

[![Repository](https://img.shields.io/badge/repo-byronbayer%2FPowershell-blue)](https://github.com/byronbayer/Powershell)
[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-blue)](https://docs.microsoft.com/en-us/powershell/)
[![Azure](https://img.shields.io/badge/Azure-Az%20Module-0089D6)](https://docs.microsoft.com/en-us/powershell/azure/)
[![License](https://img.shields.io/badge/license-MIT-green)](LICENSE)

A comprehensive collection of Azure and PowerShell utility scripts for resource management, automation, and administration tasks. This repository contains production-ready scripts for managing Azure resources, automating deployments, and performing common administrative operations.

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
- [Python Scripts](#python-scripts)
- [Project Folders](#project-folders)
- [Getting Started](#getting-started)

---

> 💡 **Navigation Tip:** Use `Ctrl+F` to search for specific scripts or features. All scripts are organized by category below.

---

## Azure Service Bus

### CallServiceBus.ps1

**Category:** Azure Messaging | **Complexity:** Intermediate | **Prerequisites:** Az.ServiceBus module

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

**Documentation:** [Calling Azure Service Bus from PowerShell with SAS Authentication Token](https://medium.com/@byronbayer/calling-azure-service-bus-from-powershell-with-sas-authentication-token-eabf828398c8)

**Prerequisites:** Azure PowerShell Az module, Service Bus namespace with appropriate permissions

---

## Azure Resource Management

### GetAzureApiVersions.ps1

**Category:** Azure ARM/Bicep | **Complexity:** Intermediate | **Prerequisites:** Az.Resources module

Advanced Azure API version discovery tool with filtering and template generation capabilities. Essential for Infrastructure as Code (IaC) development with ARM templates and Bicep.

**Related Scripts:** See also [update-terraform.ps1](#update-terraformps1) for Terraform version management

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

**Category:** Azure Setup | **Complexity:** Simple | **Prerequisites:** Az.Resources module

Intelligent resource provider registration that only registers unregistered providers. Checks current registration status before attempting registration to avoid unnecessary operations.

**Function:** `Register-ResourceProviders`

**Common Providers:**
- `Microsoft.Storage` - Storage accounts, blobs, files
- `Microsoft.Compute` - Virtual machines, disks
- `Microsoft.Network` - VNets, NSGs, load balancers
- `Microsoft.Web` - App Services, Functions
- `Microsoft.DataFactory` - Data integration pipelines
- `Microsoft.Sql` - SQL databases and servers

```powershell
$resourceProviders = @(
    "microsoft.documentdb",
    "microsoft.insights", 
    "microsoft.servicebus",
    "microsoft.sql",
    "microsoft.storage",
    "microsoft.web",
    "Microsoft.DataFactory",
    "Microsoft.AAD"
)
Register-ResourceProviders -resourceProviders $resourceProviders
```

### Remove Deployments greater then x days.ps1

**Category:** Azure Cleanup | **Complexity:** Intermediate | **Prerequisites:** Az.Resources module

Cross-subscription deployment cleanup with filtering and reporting capabilities. Helps manage Azure deployment history limits (800 deployments per resource group).

**Why Use This:** Azure has a limit of 800 deployments per resource group. When exceeded, new deployments fail with "DeploymentQuotaExceeded" error.

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

**Category:** Azure Security/Compliance | **Complexity:** Intermediate | **Prerequisites:** Az.Websites module

Comprehensive Azure Web App and certificate auditing tool for TLS compliance and security assessment.

**Primary Use Case:** Identifying Web Apps using deprecated TLS 1.0/1.1 protocols for migration to TLS 1.2+ to meet security compliance requirements.

**Output Formats:** CSV, XML, JSON (all three generated automatically)

**Key Features:**

- Identifies TLS version configurations
- Checks HttpsOnly enablement
- Retrieves certificate details and expiry dates
- Exports data in multiple formats (CSV, XML, JSON)

---

## Virtual Machine Management

### GetVmDetails.ps1

**Category:** Azure VMs/Inventory | **Complexity:** Simple | **Prerequisites:** Az.Compute module

Comprehensive virtual machine inventory and configuration reporting tool. Useful for asset management, capacity planning, and compliance auditing.

**Function:** `Get-VmDetails`

**Features:**

- Cross-subscription VM discovery
- Detailed configuration extraction
- Network topology mapping
- Export-ready output format

**Output includes:**

- Resource group and location
- VM size and OS type
- Network interface and VNET/Subnet details
- Provisioning state and availability zones
- Associated disks and storage

**Related Scripts:** See [ShutDownVms.ps1](#shutdownvmsps1) and [StartVmsInOrder](#startvmsinorder) for VM power management

### ShutDownVms.ps1

**Category:** Azure VMs/Operations | **Complexity:** Simple | **Prerequisites:** Az.Compute module

⚠️ **Warning:** Stops ALL VMs in the current subscription. Use with caution in production environments.

Shuts down all virtual machines in a subscription. Useful for cost savings during non-business hours or for development/test environments.

**Function:** `Stop-Machines`

```powershell
# Stop all VMs in current subscription
Stop-Machines

# Preview what would be stopped
Stop-Machines -WhatIf
```

**Cost Savings:** Stopped (deallocated) VMs don't incur compute charges, only storage costs for disks.

### StartVmsInOrder/StartVms.ps1

**Category:** Azure VMs/Operations | **Complexity:** Intermediate | **Prerequisites:** Az.Compute module

Starts virtual machines in a specific order (sequential) or all together (parallel). Essential for applications with dependencies like domain controllers, database servers, and application tiers.

```powershell
$MachineNames = "jf-vm-002", "jf-vm-001"
Start-Machines -MachineNames $MachineNames -PreserveOrder $true
```

---

## Azure Active Directory Management

### Remove-AADAppRegistrationsWithPattern.ps1

**Category:** Azure AD/Cleanup | **Complexity:** Advanced | **Prerequisites:** AzureAD module, Global Admin rights

⚠️ **Warning:** Permanently deletes app registrations. Test with `-WhatIf` first.

Bulk Azure AD application registration cleanup tool with pattern-based filtering. Ideal for cleaning up test environments or removing deprecated applications.

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

> 💡 **Best Practice:** Always use `-WhatIf` parameter first to preview deletions before executing.

### Remove-DefinedFilesFolderLocation.ps1

**Category:** Local Filesystem | **Complexity:** Simple | **Prerequisites:** None

⚠️ **Warning:** Recursively deletes files matching patterns. Test with `-WhatIf` first.

Deletes files matching specified include patterns while respecting exclude patterns. Perfect for cleaning build artifacts, cache files, and temporary data from development directories.

**Function:** `Remove-DefinedFilesFolderLocation`

**Pattern Matching:** Supports wildcards (`*`, `?`) for flexible file matching

```powershell
$include = @("*ncrunch*", "*.suo", "*.user", "*.userosscache", "*.sln.docstates", "*ncrunch*", ".vs", "bin", "obj", "build")
$exclude = @()
Remove-DefinedFilesFolderLocation -FolderLocation "C:\Dev\" -Include $include -Exclude $exclude -WhatIf
```

### Remove-Disks.ps1

**Category:** Azure Cleanup/Storage | **Complexity:** Simple | **Prerequisites:** Az.Compute module

Removes unattached managed disks to reduce storage costs. Unattached disks continue to incur charges even when not in use.

**Function:** `Remove-Disks`

**Cost Savings:** Removing unused disks can significantly reduce monthly storage costs.

```powershell
# Find and remove all unattached disks
$DisksToDelete = (Get-AzDisk | Where-Object DiskState -EQ 'Unattached').Name
Remove-Disks -DisksToDelete $DisksToDelete

# Or specify disks manually
$DisksToDelete = "disk1", "disk2", "disk3"
Remove-Disks -DisksToDelete $DisksToDelete
```

### Remove-Nics.ps1

**Category:** Azure Cleanup/Networking | **Complexity:** Simple | **Prerequisites:** Az.Network module

Removes orphaned network interfaces (NICs) left behind after VM deletions.

**Function:** `Remove-Nics`

```powershell
$NICsToDelete = "nic1", "nic2", "nic3"
Remove-Nics -NICsToDelete $NICsToDelete
```

### Remove-ResourcegroupsAsync.ps1

**Category:** Azure Cleanup | **Complexity:** Advanced | **Prerequisites:** Az.Resources module

⚠️ **Warning:** Deletes entire resource groups and all contained resources. Cannot be undone.

Parallel resource group deletion utility using PowerShell background jobs for efficient bulk cleanup operations. Significantly faster than sequential deletion for multiple resource groups.

**Performance:** Can delete dozens of resource groups simultaneously, reducing cleanup time from hours to minutes.

**Functions:**

- `Remove-ResourceGroupsInParallel` - Executes parallel deletion using background jobs
- `Remove-ResourceGroupsAsync` - Main function with pattern matching and confirmation

**Parameters:**

- `-ResourceGroupNamePatterns` - Array of resource group name patterns (supports wildcards)
- `-RemoveLocks` - Optional flag to remove resource locks before deletion

**Key Features:**

- Parallel execution using PowerShell background jobs
- Pattern-based resource group matching
- Interactive confirmation with resource group preview
- Optional lock removal capability
- Job status monitoring and cleanup
- Performance tracking for completed jobs

```powershell
# Create test resource groups
for ($i = 1; $i -lt 10; $i++) {
    New-AzResourceGroup -Name "my-rg-00$i" -Location 'UK South' -Confirm:$false -Force | Out-Null
    New-AzResourceGroup -Name "test-rg-00$i" -Location 'UK South' -Confirm:$false -Force | Out-Null
}

# Delete resource groups with patterns, removing locks first
$ResourceGroupNamePatterns = "my-rg*", "test-rg*"
Remove-ResourceGroupsAsync -ResourceGroupNamePatterns $ResourceGroupNamePatterns -RemoveLocks $true
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

**Category:** Azure Data Factory | **Complexity:** Advanced | **Prerequisites:** Az.DataFactory module

Changes the scale and location of an SQL Server Integration Services (SSIS) Integration Runtime instance in Azure Data Factory. Useful for optimizing performance and costs.

**Function:** `Update-SSISIR`

**Parameters:**
- `-subscription` - Azure subscription ID
- `-resourceGroupName` - Resource group containing the Data Factory
- `-nodeSize` - VM size for SSIS IR nodes (e.g., Standard_D2_v3)
- `-location` - Azure region

```powershell
Update-SSISIR -subscription "your-sub-id" `
    -resourceGroupName "rg-datafactory" `
    -nodeSize "Standard_D4_v3" `
    -location "eastus"
```

**Cost Optimization:** Scale down during off-peak hours, scale up for heavy workloads.

---

## Tagging & Organization

> 💡 **Best Practice:** Use tags for cost tracking, ownership, environment identification, and compliance requirements.

### TagResourceGroupsFromResources.ps1

**Category:** Azure Tags | **Complexity:** Simple | **Prerequisites:** Az.Resources module

Inherits tags from child resources to parent resource group when the resource group has no tags. Useful for standardizing tagging after resources are created.

**Function:** `Add-TagsToResourceGroupFromResources`

**Use Case:** When resources are properly tagged but resource groups are not.

```powershell
Add-TagsToResourceGroupFromResources
```

### TagResourcesFromResourceGroup.ps1

**Category:** Azure Tags | **Complexity:** Simple | **Prerequisites:** Az.Resources module

Applies tags from parent resource group to all child resources. Ensures consistent tagging across all resources in a group.

**Function:** `Add-TagsToResourcesFromResourceGroups`

**Use Case:** When resource group is properly tagged but resources need the same tags.

```powershell
Add-TagsToResourcesFromResourceGroups
```

**Related Scripts:** See [TagResourceGroupsFromResources.ps1](#tagresourcegroupsfromresourcesps1) for opposite direction.

### RemoveAllTagsForResourceGroup.ps1

**Category:** Azure Tags | **Complexity:** Simple | **Prerequisites:** Az.Resources module

Removes all tags from a resource group and optionally from all resources within that resource group. Useful for tag cleanup or restructuring.

**Function:** `Remove-AllTags`

```powershell
Remove-AllTags -ResourceGroup "MyResourceGroup" -IncludeResources $true
```

---

## Git & Repository Management

### git-GetLatestVersionOfAllRepositories 1.ps1

**Category:** DevOps/Git | **Complexity:** Advanced | **Prerequisites:** Git CLI, Azure DevOps PAT

Enterprise-scale Git repository management tool for Azure DevOps organizations. Automates the process of cloning and updating hundreds of repositories across multiple organizations.

**Function:** `Get-AllRepos`

**Parameters:**

- `-connectionToken` - Azure DevOps personal access token
- `-rootFolder` - Local repository root directory
- `-organisations` - Array of Azure DevOps organizations
- `-fetchOnly` - Fetch-only mode (no pulls)
- `-IgnoreProjects` - Projects to skip (exclusion filter)
- `-includeProjects` - Projects to include (inclusion filter, overrides ignore)

**Features:**

- Multi-organization support
- Git-enabled project detection
- Repository cloning for missing repos
- Intelligent branch handling (main/master)
- Fetch and pull operations
- Dual filtering: inclusion and exclusion lists
- Error handling and retry logic with 5 attempts
- Automatic directory creation

**Filtering Logic:**
- If `-includeProjects` is specified, only those projects are processed
- `-IgnoreProjects` is checked second for exclusions
- Both can be used together for fine-grained control

```powershell
# Include only specific projects
Get-AllRepos -connectionToken "your-pat-token" `
    -rootFolder "C:\Dev" `
    -organisations @("MyOrg1", "MyOrg2") `
    -includeProjects @("project1", "project2")

# Exclude specific projects
Get-AllRepos -connectionToken "your-pat-token" `
    -rootFolder "C:\Dev" `
    -organisations @("MyOrg1", "MyOrg2") `
    -IgnoreProjects @("archived-proj1", "legacy-proj2")

# Fetch only (no pull)
Get-AllRepos -connectionToken "your-pat-token" `
    -rootFolder "C:\Dev" `
    -organisations @("MyOrg") `
    -fetchOnly
```

---

## Development Tools

### Switch-AzureRmWithAz.ps1

**Category:** PowerShell/Migration | **Complexity:** Simple | **Prerequisites:** PowerShellGet module

⚠️ **Note:** AzureRM is deprecated. This script helps migrate to the Az module.

Replaces deprecated AzureRm PowerShell modules with the modern Az modules. Essential for maintaining compatibility with latest Azure features.

**Function:** `Switch-AzureRmWithAz`

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

---

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

**Category:** Utilities/Logging | **Complexity:** Simple | **Prerequisites:** None

Color-coded logging utility with timestamp tracking. Enhances script output readability and helps track execution time for different operations.

**Function:** `Write-Message`

**Features:**
- Elapsed time tracking with stopwatch integration
- Color-coded output for better visibility
- Optional standalone messages without stopwatch
- Millisecond precision timing

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

## Python Scripts

### password_input.py

**Category:** Python/Utilities | **Complexity:** Beginner | **Prerequisites:** Python 3.x

Interactive password validation utility with length requirements. Educational example for learning Python input validation.

**Location:** `python/password_input.py`

**Features:**

- Interactive password input prompting
- Minimum length validation (10+ characters)
- Loop-based retry mechanism
- User-friendly error messages
- Input confirmation display

**Usage:**

```bash
python python/password_input.py
```

**Behavior:**

- Prompts user for password input
- Validates minimum length requirement (>10 characters)
- Re-prompts if password is too short with character count feedback
- Displays success message with password confirmation once valid

**Use Cases:**

- Testing password input validation logic
- Learning Python input/output basics
- Quick password strength validation demonstrations
- Template for more complex password validation scripts

---

## Project Folders

> 📚 **Note:** These are complete project folders containing multiple files and dependencies.

### Create-AzVmsFromExcel/

**Category:** Azure VMs/Provisioning | **Complexity:** Advanced | **Prerequisites:** Az modules, ImportExcel

Enterprise-grade VM provisioning system using Excel-driven configuration. Simplifies bulk VM deployment with ARM templates and parameter management.

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

**Category:** Server Management/Remote Operations | **Complexity:** Intermediate | **Prerequisites:** PowerShell Remoting, WinRM

Remote server management and file discovery tools for Windows Server environments. Enables centralized file auditing and remote script execution.

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

**Category:** Azure VMs/Operations | **Complexity:** Intermediate | **Prerequisites:** Az.Compute module

VM startup orchestration with dependency management. Ideal for applications requiring specific startup sequences.

**File:** `StartVms.ps1`

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

**Category:** Storage/Testing | **Complexity:** Intermediate | **Prerequisites:** ImportExcel, Azure Files access

Comprehensive file share connectivity and permissions testing framework. Validates Azure Files and network share accessibility with automated testing.

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

## Quick Start

```powershell
# 1. Install required modules
Install-Module -Name Az -AllowClobber -Scope CurrentUser
Install-Module -Name ImportExcel -Scope CurrentUser

# 2. Connect to Azure
Connect-AzAccount
Set-AzContext -SubscriptionId "your-subscription-id"

# 3. Set execution policy (if needed)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# 4. Run any script
.\ScriptName.ps1
```

## Getting Started

### Prerequisites

#### Required Software

- **PowerShell 5.1 or later** (PowerShell 7+ recommended for cross-platform support)
  - [Download PowerShell](https://github.com/PowerShell/PowerShell/releases)
  - Check version: `$PSVersionTable.PSVersion`

- **Azure PowerShell modules (Az.*)** - v10.0+ recommended
  - [Azure PowerShell Documentation](https://docs.microsoft.com/en-us/powershell/azure/)
  
  ```powershell
  Install-Module -Name Az -AllowClobber -Scope CurrentUser -Force
  ```

#### Optional Modules

- **ImportExcel module** - Required for Excel-based scripts ([Create-AzVmsFromExcel](#create-azvmsfromexcel), [TestFilesShares](#testfilesshares))
  
  ```powershell
  Install-Module -Name ImportExcel -Scope CurrentUser -Force
  ```

- **AzureAD module** - Required for [Remove-AADAppRegistrationsWithPattern.ps1](#remove-aadappregistrationswithpatternps1)
  
  ```powershell
  Install-Module -Name AzureAD -Scope CurrentUser -Force
  ```

#### Azure Access

- **Active Azure subscription** with appropriate permissions
- **Azure authentication** configured
  
  ```powershell
  Connect-AzAccount
  Get-AzContext  # Verify connection
  ```

### Common Setup Steps

#### 1. Set Execution Policy (First Time Only)

Allows running downloaded scripts:

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

#### 2. Install Required Modules

```powershell
# Core Azure modules (required for most scripts)
Install-Module Az -AllowClobber -Scope CurrentUser -Force

# Excel integration (for Excel-based scripts)
Install-Module ImportExcel -Scope CurrentUser -Force

# Azure AD (for AAD app registration scripts)
Install-Module AzureAD -Scope CurrentUser -Force
```

#### 3. Connect to Azure

```powershell
# Interactive login
Connect-AzAccount

# Verify connection
Get-AzContext

# Switch to specific subscription
Set-AzContext -SubscriptionId "your-subscription-id"

# List all available subscriptions
Get-AzSubscription
```

#### 4. Verify Module Installation

```powershell
# Check installed Az modules
Get-Module -ListAvailable Az*

# Check PowerShell version
$PSVersionTable.PSVersion
```

### Best Practices

#### Safety & Testing

- ✅ **Always use `-WhatIf`** - Preview changes before execution (supported by most deletion scripts)
- ✅ **Test in dev first** - Never test cleanup scripts in production
- ✅ **Use `-Confirm`** - Enable confirmation prompts for destructive operations
- ✅ **Review variables** - Check and customize all script variables before execution
- ✅ **Backup critical data** - Take snapshots before major changes

#### Cost Management

- 💰 **Monitor Azure costs** - Use Azure Cost Management to track spending
- 💰 **Clean up test resources** - Remove unused resources promptly
- 💰 **Use resource locks** - Prevent accidental deletion of production resources
- 💰 **Stop unused VMs** - Deallocate VMs to save compute costs
- 💰 **Delete unattached disks** - Remove orphaned storage resources

#### Security & Compliance

- 🔒 **Use least privilege** - Grant minimum required permissions
- 🔒 **Store secrets securely** - Use Azure Key Vault, never hardcode credentials
- 🔒 **Enable MFA** - Multi-factor authentication for admin accounts
- 🔒 **Audit logs** - Enable Azure Activity Log and review regularly
- 🔒 **Tag resources** - Use tags for ownership, environment, and compliance tracking

#### Scripting Best Practices

- 📝 **Use approved verbs** - Follow PowerShell naming conventions (Get-, Set-, New-, Remove-)
- 📝 **Add parameter validation** - Use `[Parameter()]` attributes and validation sets
- 📝 **Implement error handling** - Use try-catch blocks and proper error actions
- 📝 **Write verbose output** - Use `Write-Verbose` for debugging information
- 📝 **Support common parameters** - Include `-WhatIf`, `-Confirm`, `-Verbose`

### Security Considerations

#### Credential Management

```powershell
# ✅ GOOD: Use SecureString for passwords
$SecurePassword = Read-Host "Enter password" -AsSecureString
$Credential = New-Object System.Management.Automation.PSCredential($Username, $SecurePassword)

# ✅ GOOD: Store secrets in Azure Key Vault
$Secret = Get-AzKeyVaultSecret -VaultName "mykeyvault" -Name "mysecret"

# ❌ BAD: Never hardcode credentials
$Password = "MyPassword123"  # DON'T DO THIS!
```

#### Access Control

- Use **Azure RBAC** for fine-grained access control
- Implement **Privileged Identity Management (PIM)** for just-in-time access
- Enable **Azure AD Conditional Access** for context-aware security
- Use **Managed Identities** instead of service principals when possible

#### Audit & Compliance

- Enable **Azure Activity Log** for all subscriptions
- Configure **diagnostic settings** for resource-level logs
- Use **Azure Policy** to enforce organizational standards
- Implement **Azure Sentinel** for security monitoring
- Regularly review **Azure Advisor** security recommendations

## Troubleshooting

### Common Issues

#### "Connect-AzAccount: The term 'Connect-AzAccount' is not recognized"

**Solution:** Install the Az module:

```powershell
Install-Module -Name Az -AllowClobber -Scope CurrentUser -Force
```

#### "Execution Policy Error: File cannot be loaded"

**Solution:** Set execution policy:

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

#### "Insufficient Privileges to Complete the Operation"

**Solution:** Verify Azure permissions:

```powershell
Get-AzRoleAssignment -SignInName (Get-AzContext).Account
```

#### "DeploymentQuotaExceeded"

**Solution:** Use [Remove Deployments greater then x days.ps1](#remove-deployments-greater-then-x-daysps1) to clean up old deployments.

#### Module Version Conflicts

**Solution:** Uninstall old versions:

```powershell
# Remove AzureRM (if still installed)
Uninstall-Module -Name AzureRM -AllVersions

# Update to latest Az module
Update-Module -Name Az -Force
```

### Getting Help

```powershell
# View script help
Get-Help .\ScriptName.ps1 -Full

# View function help
Get-Help Function-Name -Examples

# List all functions in a script
Get-Command -Module ScriptName
```

### Useful Azure PowerShell Commands

```powershell
# List all subscriptions
Get-AzSubscription

# Get current context
Get-AzContext

# List all resource groups
Get-AzResourceGroup

# Check provider registration status
Get-AzResourceProvider -ListAvailable

# View Azure PowerShell version
Get-Module Az -ListAvailable
```

---

## Frequently Asked Questions

<details>
<summary><b>Can I run these scripts on Linux or macOS?</b></summary>

Most Azure-related scripts work with PowerShell 7+ on Linux/macOS. However, some scripts using Windows-specific features may require modifications. The Az module is cross-platform compatible.
</details>

<details>
<summary><b>Do these scripts work with Azure Government or Azure China?</b></summary>

Yes, but you need to connect to the appropriate environment:

```powershell
Connect-AzAccount -Environment AzureUSGovernment
Connect-AzAccount -Environment AzureChinaCloud
```
</details>

<details>
<summary><b>How do I handle multiple Azure tenants?</b></summary>

```powershell
Connect-AzAccount -Tenant "tenant-id-here"
Set-AzContext -TenantId "tenant-id-here"
```
</details>

<details>
<summary><b>Can I automate these scripts in Azure DevOps or GitHub Actions?</b></summary>

Yes! Use service principals for authentication:

```powershell
$SecurePassword = ConvertTo-SecureString $env:AZURE_PASSWORD -AsPlainText -Force
$Credential = New-Object System.Management.Automation.PSCredential($env:AZURE_CLIENT_ID, $SecurePassword)
Connect-AzAccount -ServicePrincipal -Credential $Credential -Tenant $env:AZURE_TENANT_ID
```
</details>

<details>
<summary><b>What's the difference between AzureRM and Az modules?</b></summary>

Az is the modern replacement for AzureRM. AzureRM is deprecated and no longer receives updates. Use [Switch-AzureRmWithAz.ps1](#switch-azurermwithazps1) to migrate.
</details>

<details>
<summary><b>How do I contribute a new script?</b></summary>

See the [Contributing](#contributing) section for guidelines on adding new scripts and updating documentation.
</details>

---

## Repository Structure

```
Powershell/
├── *.ps1                          # PowerShell scripts
├── python/                        # Python utilities
│   └── password_input.py
├── Create-AzVmsFromExcel/         # VM provisioning system
├── ListFoldersOnAllServers/       # Remote server management
├── StartVmsInOrder/               # VM orchestration
└── TestFilesShares/               # File share testing
```

## Contributing

When adding new scripts:

1. **Follow PowerShell best practices** (approved verbs, parameter validation)
2. **Include comprehensive error handling**
3. **Add parameter sets and help documentation**
4. **Support `-WhatIf` and `-Confirm` where applicable**
5. **Include usage examples and parameter descriptions**
6. **Test across multiple Azure subscriptions/tenants**
7. **Document dependencies and prerequisites**
8. **Update this README** with script documentation

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Author

**Byron Bayer**
- GitHub: [@byronbayer](https://github.com/byronbayer)
- Medium: [@byronbayer](https://medium.com/@byronbayer)

## Changelog

### 2025-12-17
- ✨ Added Python scripts section with `password_input.py` documentation
- 📝 Enhanced documentation formatting with category tags and complexity indicators
- 🔗 Added cross-references between related scripts
- ⚠️ Added warning indicators for destructive operations
- 💡 Added best practices, security considerations, and troubleshooting sections
- 📚 Added FAQ section with common questions
- 🚀 Improved examples with real-world use cases
- 🎯 Added Quick Start guide for faster onboarding
- 📊 Added cost optimization and compliance guidance
- 🎨 Added repository badges and improved visual hierarchy

---

## Resources & Related Links

### Official Documentation

- [Azure PowerShell Documentation](https://docs.microsoft.com/en-us/powershell/azure/)
- [Azure PowerShell Reference](https://docs.microsoft.com/en-us/powershell/module/)
- [Azure CLI Documentation](https://docs.microsoft.com/en-us/cli/azure/)
- [PowerShell Gallery](https://www.powershellgallery.com/)

### Microsoft Learn Resources

- [Azure Administrator Learning Path](https://docs.microsoft.com/en-us/learn/paths/azure-administrator/)
- [Automate Azure tasks using PowerShell](https://docs.microsoft.com/en-us/learn/modules/automate-azure-tasks-with-powershell/)
- [Manage Azure resources with PowerShell](https://docs.microsoft.com/en-us/learn/modules/manage-azure-resources-with-powershell/)

### Tools & Extensions

- [Visual Studio Code](https://code.visualstudio.com/) - Recommended editor
- [PowerShell Extension for VS Code](https://marketplace.visualstudio.com/items?itemName=ms-vscode.PowerShell)
- [Azure Account Extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode.azure-account)
- [Azure CLI Tools](https://marketplace.visualstudio.com/items?itemName=ms-vscode.azurecli)

### Community Resources

- [PowerShell Community](https://devblogs.microsoft.com/powershell/)
- [Azure PowerShell GitHub](https://github.com/Azure/azure-powershell)
- [PowerShell Gallery](https://www.powershellgallery.com/)
- [Reddit r/PowerShell](https://www.reddit.com/r/PowerShell/)
- [Reddit r/Azure](https://www.reddit.com/r/AZURE/)

### Related Projects

- [Azure-Samples](https://github.com/Azure-Samples) - Official Azure code samples
- [Azure Quick Start Templates](https://github.com/Azure/azure-quickstart-templates) - ARM template library
- [Terraform Azure Modules](https://registry.terraform.io/namespaces/Azure) - Infrastructure as Code

---

**Last Updated:** December 17, 2025 | **Maintained by:** [Byron Bayer](https://github.com/byronbayer)
