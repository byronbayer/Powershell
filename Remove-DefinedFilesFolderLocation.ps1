function Remove-DefinedFilesFolderLocation {
    param(
        # Parameter help description
        [Parameter(Mandatory = $true)]
        [string]
        $FolderLocation
    )

    Set-Location $FolderLocation
    $include = @("*ncrunch*", "*.suo", "*.user", "*.userosscache", "*.sln.docstates", "*ncrunch*", ".vs", "bin", "obj", "build")
    $exclude = @()

    $items = Get-ChildItem . -Recurse -Force -Include $include -Exclude $exclude

    foreach ($item in $items) {
        Remove-Item $item.FullName -Force -Recurse -ErrorAction SilentlyContinue
        Write-Host "Deleted " $item.FullName
    }
}
Clear-DefinedFilesFolderLocation -FolderLocation "C:\Dev\Spikes"
