.'..\RegisterProviders.ps1'
.'.\Provisioning-Functions.ps1'
Set-Location $PSScriptRoot
$path = ".\Azure Virtual Machine Configuration.xlsx"
$xlMachines = New-Object System.Collections.ArrayList

Import-ExcelModule

foreach ($xlMachine in (Import-Excel -Path $path -StartRow 1)) {
    $xlMachines.Add($xlMachine) | Out-Null   
}
#$xlMachines
New-Infrastrucure -Machines $xlMachines
