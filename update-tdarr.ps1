<#
.SYNOPSIS
    Downloads and extracts the latest Tdarr Node for Windows.

.DESCRIPTION
    This script defines a function that fetches the latest version information for Tdarr 
    from the official versions.json file, downloads the latest Tdarr_Node package for 
    Windows (x64), and extracts it to a specified folder.

.PARAMETER DestinationPath
    The folder where the Tdarr Node files will be extracted. This folder will be created if it doesn't exist.

.EXAMPLE
    Update-TdarrNode -DestinationPath "C:\Tdarr\Node"

    This will download the latest Tdarr Node and extract it to the "C:\Tdarr\Node" folder.
#>
<#
.LINK
    https://github.com/byronbayer/Powershell#update-tdarrps1
#>

function Update-TdarrNode {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$DestinationPath
    )

    # The URL for the Tdarr versions JSON file
    $versionsUrl = "https://storage.tdarr.io/versions.json"

    try {
        # Step 1: Download the versions.json file
        Write-Host "Fetching version information from $versionsUrl..."
        $versionsJson = Invoke-RestMethod -Uri $versionsUrl

        # Step 2: Find the download URL for the latest Windows x64 Tdarr Node
        Write-Host "Finding the latest Tdarr Node for Windows (x64)..."

        # Get all version strings from the JSON keys and sort them to find the latest.
        # The `-replace` handles potential beta tags that [System.Version] cannot parse.
        $latestVersionString = $versionsJson.PSObject.Properties.Name | Sort-Object -Property { [System.Version]($_ -replace '-beta.*', '') } -Descending | Select-Object -First 1

        if (-not $latestVersionString) {
            throw "Could not determine the latest version from the versions file."
        }

        # Check local version
        $localVersionPath = Join-Path -Path $DestinationPath -ChildPath "version.txt"
        if (Test-Path -Path $localVersionPath) {
            $localVersionString = Get-Content -Path $localVersionPath
            
            # Normalize versions for comparison
            $latestComparableVersion = [System.Version]($latestVersionString -replace '-beta.*', '')
            $localComparableVersion = [System.Version]($localVersionString -replace '-beta.*', '')

            if ($localComparableVersion -ge $latestComparableVersion) {
                Write-Host "You already have the latest version of Tdarr Node: $localVersionString"
                return
            }
        }

        # Get the package details for the latest version using the correct hierarchical structure
        $downloadUrl = $versionsJson.$latestVersionString.win32_x64.Tdarr_Node

        if (-not $downloadUrl) {
            throw "Could not find a download link for Tdarr Node for Windows (x64) for version $latestVersionString."
        }

        # The JSON no longer provides a 'fileName' property, so we extract it from the URL
        $fileName = Split-Path -Path $downloadUrl -Leaf
        $version = $latestVersionString

        Write-Host "Found version $version. Download URL: $downloadUrl"

        # Step 3: Download the Tdarr Node zip file
        $downloadPath = Join-Path -Path $env:TEMP -ChildPath $fileName
        Write-Host "Downloading $fileName to $downloadPath..."
        Invoke-WebRequest -Uri $downloadUrl -OutFile $downloadPath

        # Step 4: Create the destination folder if it doesn't exist
        if (-not (Test-Path -Path $DestinationPath)) {
            Write-Host "Creating destination folder: $DestinationPath"
            New-Item -ItemType Directory -Path $DestinationPath | Out-Null
        }

        # Step 5: Extract the contents of the zip file
        Write-Host "Extracting $fileName to $DestinationPath..."
        Expand-Archive -Path $downloadPath -DestinationPath $DestinationPath -Force

        # Step 6: Clean up the downloaded zip file
        Write-Host "Cleaning up temporary files..."
        Remove-Item -Path $downloadPath

        # Step 7: Save the current version to a file
        Write-Host "Saving version information..."
        Set-Content -Path $localVersionPath -Value $latestVersionString

        Write-Host "Tdarr Node version $version has been successfully downloaded and extracted to $DestinationPath"
    }
    catch {
        Write-Error "An error occurred: $($_.Exception.Message)"
    }
}

# Example of how to call the function:
# Update-TdarrNode -DestinationPath "C:\Tdarr\Node"

# Update-TdarrNode -DestinationPath "D:\Tdarr\Tdarr_Node"