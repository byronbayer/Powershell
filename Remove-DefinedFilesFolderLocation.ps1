<#
.LINK
    https://github.com/byronbayer/Powershell#remove-definedfilesfolderlocationps1
#>

function Remove-DefinedFilesFolderLocation {
    [cmdletbinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $true)]
        [string]
        $FolderLocation,
        [Parameter()]
        [string[]]
        $Include,
        [Parameter()]
        [string[]]
        $Exclude
    )

    if (Test-Path $FolderLocation) {
        Set-Location $FolderLocation
        $items = Get-ChildItem . -Recurse -Force -Include $Include -Exclude $Exclude
        foreach ($item in $items) {
            Remove-Item $item.FullName -Force -Recurse -ErrorAction SilentlyContinue
            Write-Host "Deleted " $item.FullName
        }
    }
}
$include = @("*ncrunch*", "*.suo", "*.user", "*.userosscache", "*.sln.docstates", "*ncrunch*", ".vs", "bin", "obj", "build")
$exclude = @()
Remove-DefinedFilesFolderLocation -FolderLocation "C:\Dev\" -Include $include -Exclude $exclude -WhatIf
