function Update-Terraform {
    <#
    .SYNOPSIS
        Updates Terraform to the latest version or installs it if not present.
    
    .DESCRIPTION
        This function checks for the current Terraform installation, compares it with the latest 
        available version from HashiCorp releases, and updates or installs Terraform accordingly.
        If Terraform is not installed, it will be installed to the specified folder.
    
    .PARAMETER InstallPath
        The folder where Terraform should be installed if not already present. 
        Defaults to "$env:ProgramFiles\Terraform" if not specified.
    
    .PARAMETER Force
        Forces reinstallation even if Terraform is already up to date.
    
    .EXAMPLE
        Update-Terraform
        Updates Terraform using the default installation path.
    
    .EXAMPLE
        Update-Terraform -InstallPath "C:\Tools\Terraform"
        Updates or installs Terraform to the specified folder.
    
    .EXAMPLE
        Update-Terraform -Force
        Forces reinstallation of Terraform even if it's already the latest version.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$InstallPath = "$env:ProgramFiles\Terraform",
        
        [Parameter(Mandatory = $false)]
        [switch]$Force
    )
    
    try {
        # Find current terraform installation
        $terraformExe = Get-Command terraform -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source
        $isInstalled = $null -ne $terraformExe
        
        if (-not $isInstalled) {
            Write-Host "Terraform is not installed or not in PATH. Will install to: $InstallPath" -ForegroundColor Yellow
            $extractPath = $InstallPath
            $installedVersion = $null
        } else {
            # Get installed terraform version
            $installedVersion = (& $terraformExe version | Select-String -Pattern "Terraform v([\d\.]+)" | ForEach-Object { $_.Matches[0].Groups[1].Value })
            Write-Host "Installed Terraform version: $installedVersion" -ForegroundColor Green
            $extractPath = Split-Path $terraformExe
        }
        
        # Get latest version from HashiCorp releases
        Write-Host "Checking for latest Terraform version..." -ForegroundColor Cyan
        $latestVersion = Invoke-RestMethod -Uri "https://api.github.com/repos/hashicorp/terraform/releases/latest" | Select-Object -ExpandProperty tag_name
        $latestVersion = $latestVersion.TrimStart('v')
        Write-Host "Latest Terraform version: $latestVersion" -ForegroundColor Green
        
        # Compare versions
        if ($isInstalled -and $installedVersion -eq $latestVersion -and -not $Force) {
            Write-Host "Terraform is already up to date." -ForegroundColor Green
            return
        }
        
        # Determine OS and architecture
        switch ($env:PROCESSOR_ARCHITECTURE) {
            "AMD64" { $arch = "amd64" }
            "ARM64" { $arch = "arm64" }
            "X86"   { $arch = "386" }
            default {
                throw "Unsupported architecture: $($env:PROCESSOR_ARCHITECTURE)"
            }
        }
        
        $os = "windows"
        $zipName = "terraform_${latestVersion}_${os}_${arch}.zip"
        $url = "https://releases.hashicorp.com/terraform/$latestVersion/$zipName"
        $tempZip = "$env:TEMP\$zipName"
        
        # Create installation directory if it doesn't exist
        if (-not (Test-Path $extractPath)) {
            Write-Host "Creating installation directory: $extractPath" -ForegroundColor Yellow
            New-Item -ItemType Directory -Path $extractPath -Force | Out-Null
        }
        
        # Download latest terraform
        Write-Host "Downloading $url ..." -ForegroundColor Cyan
        Invoke-WebRequest -Uri $url -OutFile $tempZip -UseBasicParsing
        
        # Extract and install/update
        Write-Host "Extracting Terraform to $extractPath..." -ForegroundColor Cyan
        Expand-Archive -Path $tempZip -DestinationPath $extractPath -Force
        Remove-Item $tempZip -Force
        
        $newTerraformExe = Join-Path $extractPath "terraform.exe"
        if ($isInstalled) {
            Write-Host "Terraform updated at $newTerraformExe" -ForegroundColor Green
        } else {
            Write-Host "Terraform installed at $newTerraformExe" -ForegroundColor Green
        }
        
        # Ensure PATH contains terraform location
        $userPath = [System.Environment]::GetEnvironmentVariable("Path", "User")
        $machinePath = [System.Environment]::GetEnvironmentVariable("Path", "Machine")
        
        $pathUpdated = $false
        if ($userPath -notlike "*$extractPath*" -and $machinePath -notlike "*$extractPath*") {
            try {
                # Try to update machine PATH first (requires admin)
                [System.Environment]::SetEnvironmentVariable("Path", "$machinePath;$extractPath", "Machine")
                Write-Host "Machine PATH updated to include $extractPath" -ForegroundColor Green
                $pathUpdated = $true
            } catch {
                # Fall back to user PATH if machine PATH update fails
                [System.Environment]::SetEnvironmentVariable("Path", "$userPath;$extractPath", "User")
                Write-Host "User PATH updated to include $extractPath" -ForegroundColor Yellow
                $pathUpdated = $true
            }
        }
        
        if ($pathUpdated) {
            Write-Host "Restart your terminal to apply PATH changes." -ForegroundColor Yellow
        } else {
            Write-Host "PATH already contains $extractPath." -ForegroundColor Green
        }
        
        # Verify installation
        $newVersion = (& $newTerraformExe version | Select-String -Pattern "Terraform v([\d\.]+)" | ForEach-Object { $_.Matches[0].Groups[1].Value })
        Write-Host "Verification: Terraform $newVersion is now available at $newTerraformExe" -ForegroundColor Green
        
    } catch {
        Write-Error "An error occurred while updating Terraform: $($_.Exception.Message)"
        throw
    }
}

# Example usage:
Update-Terraform
# Update-Terraform -InstallPath "C:\Tools\Terraform"
# Update-Terraform -Force
