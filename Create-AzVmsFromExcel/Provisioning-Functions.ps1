function Generate-Password ($IsProductionEnvironment, $length = 20, $nonAlphaChars = 5) {
    if ($IsProductionEnvironment -eq 'false') {
        $password = '#uEcneZ5C0s@6lq%H#Il$l';
    }
    else {
        Add-Type -AssemblyName System.Web
		
        [char[]] $illegalChars = @(':', '/', '\', '@', '''', '"', ';', '.', '+', '#')

        do {
            $hasIllegalChars = $false
            $password = [System.Web.Security.Membership]::GeneratePassword($length, $nonAlphaChars)

            $illegalChars | ForEach-Object {
                if ($password -like "*$_*") {
                    $hasIllegalChars = $true
                }
            }
        } while ($hasIllegalChars)
    }

    ConvertTo-SecureString $password -AsPlainText -Force
}

function Build-TemplateParameters {
    [cmdletbinding()]
    param(
        [Parameter(Mandatory = $true)]
        [System.Object]
        $Machine
    )

    $templateParameters = New-Object -TypeName Hashtable
    #$templateParameters['Subscription'] = $Machine."Subscription"
    $templateParameters['location'] = $Machine."Location"
    $templateParameters['networkInterfaceName'] = $Machine."networkInterfaceName"
    $templateParameters['subnetName'] = $Machine."Subnet"
    $templateParameters['virtualNetworkId'] = (Get-AzVirtualNetwork -Name $Machine."Vnet").Id
    $templateParameters['virtualMachineName'] = $Machine."VM Name"

    $templateParameters['virtualMachineRG'] = $Machine."Resource Group"
    $templateParameters['osDiskType'] = $Machine."OS Disk Type"
    $templateParameters['virtualMachineSize'] = $Machine."virtualMachineSize"
    $templateParameters['adminUsername'] = $Machine."Username"
    $templateParameters['adminPassword'] = $Machine."Password"

    # $templateParameters['Availability Set'] = $Machine."Availability Set"
    # $templateParameters['Publisher'] = $Machine."Publisher"
    # $templateParameters['Offer'] = $Machine."Offer"
    # $templateParameters['sku'] = $Machine."sku"
    # $templateParameters['version'] = $Machine."version"    
    # $templateParameters['BYO Licence'] = $Machine."BYO Licence"
    # $templateParameters['NSG'] = $Machine."NSG"
    # $templateParameters['Boot Diag'] = $Machine."Boot Diag"
    # $templateParameters['OS Diag'] = $Machine."OS Diag"
    # $templateParameters['Diag storage'] = $Machine."Diag storage"
    # $templateParameters['Auto shutdown UTC time'] = $Machine."Auto shutdown UTC time"
    # $templateParameters['Extensions'] = $Machine."Extensions"
    # $templateParameters['OS Disk Size'] = $Machine."OS Disk Size"
    # $templateParameters['Disk 1 Name'] = $Machine."Disk 1 Name"
    # $templateParameters['Disk 1 Size GB'] = $Machine."Disk 1 Size GB"
    # $templateParameters['Disk 1 Type'] = $Machine."Disk 1 Type"
    # $templateParameters['Disk 1 Host caching'] = $Machine."Disk 1 Host caching"
    # $templateParameters['Disk 2 Name'] = $Machine."Disk 2 Name"
    # $templateParameters['Disk 2 Size GB'] = $Machine."Disk 2 Size GB"
    # $templateParameters['Disk 2 Type'] = $Machine."Disk 2 Type"
    # $templateParameters['Disk 2 Host caching'] = $Machine."Disk 2 Host caching"
    return $templateParameters;
}

function Create-ResourceGroup {
    [cmdletbinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $ResourceGroupName,
        [Parameter(Mandatory = $true)]
        [string] $ResourceGroupLocation     
    )
    
    #check if resource group already exists
    Write-Host "Resource Group - Checking for existing resource group..."

    $ResourceGroup = Get-AzResourceGroup -Name $ResourceGroupName -Location $ResourceGroupLocation -ErrorAction SilentlyContinue
    if ($null -eq $ResourceGroup) {
        Write-Host "Resource Group - Resource group not found. Creating..."
        $throwaway = New-AzResourceGroup -Name $ResourceGroupName -Location $ResourceGroupLocation -Verbose -Force
	
    }
    else {
        Write-Host "Resource group found, updating..."
        $throwaway = Set-AzResourceGroup -Name $ResourceGroupName
    }

}

function New-Infrastrucure {
    param (
        # Parameter help description
        [Parameter(Mandatory = $true)]
        [System.Collections.ArrayList]
        $Machines
    )
    $resourceProviders = @("microsoft.network", "microsoft.compute");
    Register-ResourceProviders -resourceProviders $resourceProviders
    foreach ($Machine in $Machines) {
        $parameters = Build-TemplateParameters -Machine $Machine
        Select-AzSubscription $Machine.Subscription
        Create-ResourceGroup -ResourceGroupName  $Machine."Resource Group" `
            -ResourceGroupLocation  $Machine.Location
    }   
}

function Import-ExcelModule {
    if ($null -eq (Get-Module ImportExcel)) {
        Install-Module ImportExcel -Force -Confirm:$false -AllowClobber
    }    
}