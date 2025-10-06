# Find current terraform installation
$terraformExe = Get-Command terraform -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source
if (-not $terraformExe) {
	Write-Host "Terraform is not installed or not in PATH."
	exit 1
}

# Get installed terraform version
$installedVersion = (& $terraformExe version | Select-String -Pattern "Terraform v([\d\.]+)" | ForEach-Object { $_.Matches[0].Groups[1].Value })
Write-Host "Installed Terraform version: $installedVersion"

# Get latest version from HashiCorp releases
$latestVersion = Invoke-RestMethod -Uri "https://api.github.com/repos/hashicorp/terraform/releases/latest" | Select-Object -ExpandProperty tag_name
$latestVersion = $latestVersion.TrimStart('v')
Write-Host "Latest Terraform version: $latestVersion"

# Compare versions
if ($installedVersion -eq $latestVersion) {
	Write-Host "Terraform is already up to date."
	exit 0
}

# Determine OS and architecture
$arch = if ($env:PROCESSOR_ARCHITECTURE -eq "AMD64") { "amd64" } else { "386" }
$os = "windows"
$zipName = "terraform_${latestVersion}_${os}_${arch}.zip"
$url = "https://releases.hashicorp.com/terraform/$latestVersion/$zipName"
$tempZip = "$env:TEMP\$zipName"

# Download latest terraform
Write-Host "Downloading $url ..."
Invoke-WebRequest -Uri $url -OutFile $tempZip

# Extract and replace
$extractPath = Split-Path $terraformExe
Expand-Archive -Path $tempZip -DestinationPath $extractPath -Force
Remove-Item $tempZip
Write-Host "Terraform updated at $terraformExe"

# Ensure PATH contains terraform location
$envPath = [System.Environment]::GetEnvironmentVariable("Path", "User")
if ($envPath -notlike "*$extractPath*") {
	[System.Environment]::SetEnvironmentVariable("Path", "$envPath;$extractPath", "User")
	Write-Host "PATH updated to include $extractPath. Restart your terminal to apply changes."
} else {
	Write-Host "PATH already contains $extractPath."
}
