function Build-TemplateParameters {
    [cmdletbinding()]
    param(
        [Parameter(Mandatory = $true)]
        [System.Object]
        $Machine
    )
    $templateParameters = New-Object -TypeName Hashtable
    $templateParameters['Subscription'] = $Machine."Subscription"
    $templateParameters['Resource Group'] = $Machine."Resource Group"
    $templateParameters['VM Name'] = $Machine."VM Name"
    $templateParameters['Region'] = $Machine."Region"
    $templateParameters['Availability Set'] = $Machine."Availability Set"
    $templateParameters['Image'] = $Machine."Image"
    $templateParameters['Size'] = $Machine."Size"
    $templateParameters['Username'] = $Machine."Username"
    $templateParameters['Password'] = $Machine."Password"
    $templateParameters['BYO Licence'] = $Machine."BYO Licence"
    $templateParameters['Vnet'] = $Machine."Vnet"
    $templateParameters['Subnet'] = $Machine."Subnet"
    $templateParameters['NIC'] = $Machine."NIC"
    $templateParameters['NSG'] = $Machine."NSG"
    $templateParameters['Boot Diag'] = $Machine."Boot Diag"
    $templateParameters['OS Diag'] = $Machine."OS Diag"
    $templateParameters['Diag storage'] = $Machine."Diag storage"
    $templateParameters['Auto shutdown UTC time'] = $Machine."Auto shutdown UTC time"
    $templateParameters['Extensions'] = $Machine."Extensions"
    $templateParameters['OS Disk Type'] = $Machine."OS Disk Type"
    $templateParameters['OS Disk Sku'] = $Machine."OS Disk Sku"
    $templateParameters['OS Disk Size'] = $Machine."OS Disk Size"
    $templateParameters['Disk 1 Name'] = $Machine."Disk 1 Name"
    $templateParameters['Disk 1 Size GB'] = $Machine."Disk 1 Size GB"
    $templateParameters['Disk 1 Type'] = $Machine."Disk 1 Type"
    $templateParameters['Disk 1 Host caching'] = $Machine."Disk 1 Host caching"
    $templateParameters['Disk 2 Name'] = $Machine."Disk 2 Name"
    $templateParameters['Disk 2 Size GB'] = $Machine."Disk 2 Size GB"
    $templateParameters['Disk 2 Type'] = $Machine."Disk 2 Type"
    $templateParameters['Disk 2 Host caching'] = $Machine."Disk 2 Host caching"
    return $templateParameters;
}

function Create-Infrastrucure {
    param (
        # Parameter help description
        [Parameter(Mandatory = $true)]
        [System.Collections.ArrayList]
        $Machines
    )
    foreach ($Machine in $Machines) {
        $parameters = Build-TemplateParameters -Machine $Machine
        Write-Host ($parameters | Format-List | Out-String)         
    }

    
}
if ($null -eq (Get-Module ImportExcel)) {
    Install-Module ImportExcel -Force -Confirm:$false -AllowClobber
    #Get-Command -Module ImportExcel        
}

$path = "C:\Users\FREEMANJ\Documents\Solution\Azure Virtual Machine Configuration.xlsx"
$xlMachines = New-Object System.Collections.ArrayList

foreach ($xlMachine in (Import-Excel -Path $path -StartRow 1)) {
    $xlMachines.Add($xlMachine) | Out-Null   
}
#$xlMachines
Create-Infrastrucure -Machines $xlMachines
