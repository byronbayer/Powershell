#!/usr/bin/env pwsh
<#
.SYNOPSIS
Test F1 (free tier) App Service Plan availability across Azure regions.
Attempts to create and destroy a plan in each region, logging success/failure.

.DESCRIPTION
This script helps identify which Azure regions have free tier App Service quota available.
It iterates through regions, attempts F1 deployment, logs the result, then destroys it.

.PARAMETER Subscription
Subscription ID or name to test in. If omitted, uses $env:ARM_SUBSCRIPTION_ID, then the
currently selected 'az' subscription (see 'az account show').

.EXAMPLE
# Pass the subscription ID positionally
pwsh .\test-free-tier-regions.ps1 cb15d752-3189-4106-a67f-2839f2965c63

.EXAMPLE
# Pass the subscription by name, and also test PostgreSQL
pwsh .\test-free-tier-regions.ps1 -Subscription "My Subscription" -TestPostgres

.EXAMPLE
# Use the environment variable
$env:ARM_SUBSCRIPTION_ID='cb15d752-3189-4106-a67f-2839f2965c63'
pwsh .\test-free-tier-regions.ps1

.EXAMPLE
# Use whichever subscription 'az' is currently set to
pwsh .\test-free-tier-regions.ps1
#>

param(
    [Parameter(Position = 0)]
    [Alias('SubscriptionId', 'SubscriptionName')]
    [string]$Subscription = $env:ARM_SUBSCRIPTION_ID,
    [string]$LogFile = ".\free-tier-test-results.log",
    [string]$ReportFile = ".\free-tier-test-results.md",
    [string]$Sku = "F1",
    [int]$MaxRegions = 0,
    [switch]$TestPostgres,
    [string]$PostgresSku = "B_Standard_B1ms",
    [string]$PostgresVersion = "16",
    [int]$PostgresStorageGb = 32,
    [int]$ThrottleLimit = 8
)

$ErrorActionPreference = "Continue"
$InformationPreference = "Continue"

function Get-SupportedAppServiceRegions {
    param(
        [Parameter(Mandatory)]
        [string]$PlanSku,

        [Parameter(Mandatory)]
        [int]$RegionLimit
    )

    Write-Host "Discovering regions that support Linux App Service SKU $PlanSku..." -ForegroundColor Yellow

    $supportedRegionOutput = az appservice list-locations --sku $PlanSku --linux-workers-enabled -o json 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to discover supported App Service locations: $($supportedRegionOutput -join ' ')"
    }

    $supportedRegionNames = $supportedRegionOutput |
        ConvertFrom-Json |
        Select-Object -ExpandProperty name

    $locationLookupOutput = az account list-locations --query "[].{name:name, displayName:displayName}" -o json 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to resolve Azure location names: $($locationLookupOutput -join ' ')"
    }

    $locationLookup = @{}
    foreach ($location in ($locationLookupOutput | ConvertFrom-Json)) {
        $locationLookup[$location.displayName] = $location.name
        $locationLookup[$location.name] = $location.name
    }

    $resolvedRegions = foreach ($supportedRegionName in $supportedRegionNames) {
        if ($locationLookup.ContainsKey($supportedRegionName)) {
            $locationLookup[$supportedRegionName]
            continue
        }

        Write-Host "WARNING: Could not resolve App Service location '$supportedRegionName' to an Azure region name." -ForegroundColor Yellow
    }

    $uniqueRegions = $resolvedRegions | Sort-Object -Unique

    if ($RegionLimit -gt 0) {
        return $uniqueRegions | Select-Object -First $RegionLimit
    }

    return $uniqueRegions
}

function ConvertTo-MarkdownCellValue {
    param(
        [AllowNull()]
        [string]$Value
    )

    if ([string]::IsNullOrWhiteSpace($Value)) {
        return "-"
    }

    return (($Value -replace "\r?\n", " ") -replace "\|", "\\|")
}

function Get-ErrorDetail {
    param(
        [AllowNull()]
        [string]$ErrorText
    )

    if ([string]::IsNullOrWhiteSpace($ErrorText)) {
        return "Unknown error"
    }

    # Extract the ERROR: portion from combined CLI output (strips WARNING: noise first)
    $errorOnly = if ($ErrorText -match 'ERROR:\s*(.+)') { $Matches[1].Trim() } else { $ErrorText }

    if ($errorOnly -match "quota") {
        return "Quota exceeded for region"
    }

    if ($errorOnly -match "capacity") {
        return "Capacity issue in region"
    }

    if ($errorOnly -match "LocationNotAvailableForResourceType|not available for creating|not supported for resource type") {
        return "Resource type not available in region"
    }

    if ($errorOnly -match "not available|not supported") {
        return "SKU/region combination not available"
    }

    if ($errorOnly -match "LocationIsOfferRestricted") {
        return "Offer restricted for subscription in region"
    }

    if ($errorOnly -match "AvailabilityZoneNotAvailable") {
        return "Availability zone not available"
    }

    return $errorOnly.Substring(0, [Math]::Min(200, $errorOnly.Length))
}

function New-StrongPassword {
    return "Aa1!" + [Guid]::NewGuid().ToString("N") + "Zz9!"
}

function Write-MarkdownReport {
    param(
        [Parameter(Mandatory)]
        [array]$TestResults,

        [Parameter(Mandatory)]
        [string]$OutputPath,

        [Parameter(Mandatory)]
        [string]$PlanSku,

        [Parameter(Mandatory)]
        [string]$SubscriptionId,

        [Parameter(Mandatory)]
        [string]$StartedAt,

        [Parameter(Mandatory)]
        [int]$SupportedRegionCount,

        [Parameter(Mandatory)]
        [bool]$PostgresWasTested
    )

    $appServiceSuccessRegions = $TestResults | Where-Object { $_.AppServiceStatus -eq "SUCCESS" } | Sort-Object Region
    $overallSuccessRegions = $TestResults | Where-Object { $_.Status -eq "SUCCESS" } | Sort-Object Region
    $failedRegions = $TestResults | Where-Object { $_.Status -eq "FAIL" } | Sort-Object Region

    if ($PostgresWasTested) {
        $postgresSuccessCount = ($TestResults | Where-Object { $_.PostgresStatus -eq "SUCCESS" }).Count
        $postgresFailedCount = ($TestResults | Where-Object { $_.PostgresStatus -eq "FAIL" }).Count
    }
    else {
        $postgresSuccessCount = 0
        $postgresFailedCount = 0
    }

    $markdown = [System.Collections.Generic.List[string]]::new()
    $markdown.Add("# App Service Region Validation Report")
    $markdown.Add("")
    $markdown.Add("- Generated: $StartedAt")
    $markdown.Add("- Subscription: $SubscriptionId")
    $markdown.Add("- SKU tested: $PlanSku")
    $markdown.Add("- PostgreSQL tested: $PostgresWasTested")
    $markdown.Add("- Supported Linux regions discovered from `az appservice list-locations`: $SupportedRegionCount")
    $markdown.Add("- Regions validated by create/delete test: $($TestResults.Count)")
    $markdown.Add("- App Service successful validations: $($appServiceSuccessRegions.Count)")
    if ($PostgresWasTested) {
        $markdown.Add("- PostgreSQL successful validations: $postgresSuccessCount")
        $markdown.Add("- PostgreSQL failed validations: $postgresFailedCount")
    }
    $markdown.Add("- Full-stack successful validations: $($overallSuccessRegions.Count)")
    $markdown.Add("- Failed validations: $($failedRegions.Count)")
    $markdown.Add("")
    $markdown.Add("> `az appservice list-locations` shows where the SKU is supported. The create/delete test below is the stronger signal for regions you can actually switch to in this subscription right now.")
    $markdown.Add("")
    $markdown.Add("## Regions you can switch to")
    $markdown.Add("")
    if ($PostgresWasTested) {
        $markdown.Add("These regions passed both App Service and PostgreSQL checks.")
    }
    else {
        $markdown.Add("These regions passed App Service checks.")
    }
    $markdown.Add("")
    $markdown.Add("| Region | Validated At |")
    $markdown.Add("| --- | --- |")

    foreach ($region in $overallSuccessRegions) {
        $markdown.Add("| $(ConvertTo-MarkdownCellValue $region.Region) | $(ConvertTo-MarkdownCellValue $region.Timestamp) |")
    }

    if ($overallSuccessRegions.Count -eq 0) {
        $markdown.Add("| - | No successful regions found |")
    }

    $markdown.Add("")
    $markdown.Add("## Per-region detail")
    $markdown.Add("")
    $markdown.Add("| Region | App Service | PostgreSQL | Overall |")
    $markdown.Add("| --- | --- | --- | --- |")

    foreach ($region in ($TestResults | Sort-Object Region)) {
        $markdown.Add("| $(ConvertTo-MarkdownCellValue $region.Region) | $(ConvertTo-MarkdownCellValue $region.AppServiceStatus) | $(ConvertTo-MarkdownCellValue $region.PostgresStatus) | $(ConvertTo-MarkdownCellValue $region.Status) |")
    }

    $markdown.Add("")
    $markdown.Add("## Failed regions")
    $markdown.Add("")
    $markdown.Add("| Region | App Service detail | PostgreSQL detail | Overall detail | Validated At |")
    $markdown.Add("| --- | --- | --- | --- | --- |")

    foreach ($region in $failedRegions) {
        $markdown.Add("| $(ConvertTo-MarkdownCellValue $region.Region) | $(ConvertTo-MarkdownCellValue $region.AppServiceDetail) | $(ConvertTo-MarkdownCellValue $region.PostgresDetail) | $(ConvertTo-MarkdownCellValue $region.ErrorDetail) | $(ConvertTo-MarkdownCellValue $region.Timestamp) |")
    }

    if ($failedRegions.Count -eq 0) {
        $markdown.Add("| - | - | - | No failures recorded | - |")
    }

    Set-Content -Path $OutputPath -Value $markdown -Encoding UTF8
}

$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$testPrefix = "jtx-freetest"
$testRgPrefix = "test-free-tier"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Free Tier App Service Plan Region Test" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# Ensure logged in
Write-Host "Checking Azure CLI authentication..." -ForegroundColor Yellow
$currentSubscriptionId = az account show --query "id" -o tsv 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Not logged into Azure CLI. Run 'az login' first." -ForegroundColor Red
    exit 1
}

# Set subscription (ID or name); fall back to the current az subscription if none supplied
if ([string]::IsNullOrWhiteSpace($Subscription)) {
    Write-Host "No -Subscription or ARM_SUBSCRIPTION_ID supplied; using current az subscription." -ForegroundColor Yellow
    $Subscription = $currentSubscriptionId
}
else {
    Write-Host "Setting subscription context..." -ForegroundColor Yellow
    $setOutput = az account set --subscription $Subscription 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERROR: Failed to set subscription '$Subscription'. Check the ID/name and that you have access (az account list -o table)." -ForegroundColor Red
        Write-Host ($setOutput -join " ") -ForegroundColor Red
        exit 1
    }
}

# Resolve to the canonical ID + name so logs and the report are unambiguous
$subscriptionInfo = az account show --query "{id:id, name:name}" -o json | ConvertFrom-Json
$Subscription = $subscriptionInfo.id

Write-Host "Subscription: $($subscriptionInfo.name) ($($subscriptionInfo.id))"
Write-Host "Test Start: $timestamp"
Write-Host "PostgreSQL test enabled: $TestPostgres"
if ($TestPostgres) {
    Write-Host "PostgreSQL SKU: $PostgresSku"
}
Write-Host ""

try {
    $regionsToTest = Get-SupportedAppServiceRegions -PlanSku $Sku -RegionLimit $MaxRegions
} catch {
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host "Discovered supported Linux regions for SKU ${Sku}: $($regionsToTest.Count)" -ForegroundColor Yellow

Write-Host "Starting region tests (parallel, throttle=$ThrottleLimit)..." -ForegroundColor Yellow
Write-Host ""

$results = $regionsToTest | ForEach-Object -ThrottleLimit $ThrottleLimit -Parallel {
    $region       = $_
    $sku          = $using:Sku
    $testPostgres = $using:TestPostgres
    $postgresSku  = $using:PostgresSku
    $pgVersion    = $using:PostgresVersion
    $pgStorage    = $using:PostgresStorageGb
    $pfx          = $using:testPrefix
    $rgPfx        = $using:testRgPrefix

    $rgName   = "$rgPfx-$region"
    $planName = "$pfx-$region"
    $msgs     = [System.Collections.Generic.List[string]]::new()

    function _GetErrorDetail {
        param([AllowNull()][string]$ErrorText)
        if ([string]::IsNullOrWhiteSpace($ErrorText)) { return "Unknown error" }
        $errorOnly = if ($ErrorText -match 'ERROR:\s*(.+)') { $Matches[1].Trim() } else { $ErrorText }
        if ($errorOnly -match "quota")                                                                          { return "Quota exceeded for region" }
        if ($errorOnly -match "capacity")                                                                       { return "Capacity issue in region" }
        if ($errorOnly -match "LocationNotAvailableForResourceType|not available for creating|not supported for resource type") { return "Resource type not available in region" }
        if ($errorOnly -match "not available|not supported")                                                    { return "SKU/region combination not available" }
        if ($errorOnly -match "LocationIsOfferRestricted")                                                      { return "Offer restricted for subscription in region" }
        if ($errorOnly -match "AvailabilityZoneNotAvailable")                                                   { return "Availability zone not available" }
        return $errorOnly.Substring(0, [Math]::Min(200, $errorOnly.Length))
    }

    $regionResult = [PSCustomObject]@{
        Region           = $region
        Status           = "FAIL"
        AppServiceStatus = "FAIL"
        AppServiceDetail = $null
        PostgresStatus   = if ($testPostgres) { "PENDING" } else { "SKIPPED" }
        PostgresDetail   = if ($testPostgres) { $null } else { "Not requested" }
        ErrorDetail      = $null
        Timestamp        = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Messages         = $null
    }

    $msgs.Add("")
    $msgs.Add("Testing region: $region")

    # Step 1: Resource group
    $msgs.Add("  → Creating resource group: $rgName")
    $rgOut = az group create --name $rgName --location $region 2>&1
    if ($LASTEXITCODE -ne 0) {
        $detail = _GetErrorDetail -ErrorText ($rgOut -join " ")
        $msgs.Add("    ✗ Resource group creation FAILED: $detail")
        $regionResult.AppServiceDetail = "Resource group creation failed: $detail"
        if ($testPostgres) {
            $regionResult.PostgresStatus = "SKIPPED"
            $regionResult.PostgresDetail = "Resource group creation failed"
        }
        $regionResult.ErrorDetail = $regionResult.AppServiceDetail
        $regionResult.Messages = $msgs.ToArray()
        return $regionResult
    }
    $msgs.Add("    ✓ Resource group created")

    # Step 2: App Service Plan
    $msgs.Add("  → Creating $sku App Service Plan: $planName")
    $planOut = az appservice plan create --name $planName --resource-group $rgName --sku $sku --is-linux 2>&1
    if ($LASTEXITCODE -ne 0) {
        $detail = _GetErrorDetail -ErrorText ($planOut -join " ")
        $msgs.Add("    ✗ App Service Plan creation FAILED: $detail")
        $regionResult.AppServiceStatus = "FAIL"
        $regionResult.AppServiceDetail = $detail
        if ($testPostgres) {
            $regionResult.PostgresStatus = "SKIPPED"
            $regionResult.PostgresDetail = "App Service test failed"
        }
    }
    else {
        $msgs.Add("    ✓ App Service Plan created successfully")
        $regionResult.AppServiceStatus = "SUCCESS"
    }

    # Step 3: PostgreSQL (only if App Service passed)
    if ($testPostgres -and $regionResult.AppServiceStatus -eq "SUCCESS") {
        $psqlName = "$pfx-$region-psql"
        $psqlPass = "Aa1!" + [Guid]::NewGuid().ToString("N") + "Zz9!"

        # Convert Terraform ARM SKU format (e.g. B_Standard_B1ms) to CLI tier + SKU name.
        # Prefix mapping: B_ → Burstable, GP_ → GeneralPurpose, MO_ → MemoryOptimized
        $pgTier = switch -Regex ($postgresSku) {
            '^B_'  { 'Burstable' }
            '^GP_' { 'GeneralPurpose' }
            '^MO_' { 'MemoryOptimized' }
            default { 'Burstable' }
        }
        $pgCliSku = $postgresSku -replace '^(B|GP|MO)_', ''

        $msgs.Add("  → Creating PostgreSQL Flexible Server: $psqlName (tier=$pgTier sku=$pgCliSku)")
        $pgOut = az postgres flexible-server create `
            --name $psqlName --resource-group $rgName --location $region `
            --tier $pgTier --sku-name $pgCliSku --version $pgVersion `
            --storage-size $pgStorage --admin-user jtxadmin --admin-password $psqlPass 2>&1
        if ($LASTEXITCODE -ne 0) {
            $detail = _GetErrorDetail -ErrorText ($pgOut -join " ")
            $msgs.Add("    ✗ PostgreSQL creation FAILED: $detail")
            $regionResult.PostgresStatus = "FAIL"
            $regionResult.PostgresDetail = $detail
        }
        else {
            $msgs.Add("    ✓ PostgreSQL created successfully")
            $regionResult.PostgresStatus = "SUCCESS"
        }
    }
    elseif ($testPostgres -and $regionResult.AppServiceStatus -ne "SUCCESS") {
        $regionResult.PostgresStatus = "SKIPPED"
        $regionResult.PostgresDetail = "App Service test failed"
    }

    # Step 4: Cleanup
    $msgs.Add("  → Cleaning up: deleting resource group $rgName")
    az group delete --name $rgName --yes --no-wait 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) {
        $msgs.Add("    ✓ Resource group deletion initiated")
    }
    else {
        $msgs.Add("    ⚠ Warning: Resource group deletion may have issues")
    }

    # Overall status
    if ($regionResult.AppServiceStatus -eq "SUCCESS" -and (-not $testPostgres -or $regionResult.PostgresStatus -eq "SUCCESS")) {
        $regionResult.Status = "SUCCESS"
    }
    else {
        if ($testPostgres -and $regionResult.PostgresStatus -eq "FAIL") {
            $regionResult.ErrorDetail = "PostgreSQL test failed"
        }
        elseif ($regionResult.AppServiceStatus -ne "SUCCESS") {
            $regionResult.ErrorDetail = "App Service test failed"
        }
        else {
            $regionResult.ErrorDetail = "Region validation failed"
        }
    }

    $regionResult.Messages = $msgs.ToArray()
    $regionResult

} | ForEach-Object {
    # Print each region's buffered output atomically as it completes
    $_.Messages | Write-Host
    $_
} | Sort-Object Region

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Test Results Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Print summary table
$successCount = ($results | Where-Object { $_.Status -eq "SUCCESS" }).Count
$failureCount = ($results | Where-Object { $_.Status -eq "FAIL" }).Count
$appServiceSuccessCount = ($results | Where-Object { $_.AppServiceStatus -eq "SUCCESS" }).Count
$postgresSuccessCount = if ($TestPostgres) { ($results | Where-Object { $_.PostgresStatus -eq "SUCCESS" }).Count } else { 0 }
$postgresFailureCount = if ($TestPostgres) { ($results | Where-Object { $_.PostgresStatus -eq "FAIL" }).Count } else { 0 }

if ($TestPostgres) {
    Write-Host "Successful regions (App Service + PostgreSQL available):" -ForegroundColor Green
}
else {
    Write-Host "Successful regions (App Service available):" -ForegroundColor Green
}

$results | Where-Object { $_.Status -eq "SUCCESS" } | ForEach-Object {
    Write-Host "  ✓ $($_.Region)" -ForegroundColor Green
}

Write-Host ""
Write-Host "Failed regions:" -ForegroundColor Red
$results | Where-Object { $_.Status -eq "FAIL" } | ForEach-Object {
    Write-Host "  ✗ $($_.Region) - $($_.ErrorDetail)" -ForegroundColor Red
}

Write-Host ""
Write-Host "Summary:" -ForegroundColor Cyan
Write-Host "  App Service successful: $appServiceSuccessCount / $($regionsToTest.Count)"
if ($TestPostgres) {
    Write-Host "  PostgreSQL successful:  $postgresSuccessCount / $($regionsToTest.Count)"
    Write-Host "  PostgreSQL failed:      $postgresFailureCount / $($regionsToTest.Count)"
}
Write-Host "  Overall successful:     $successCount / $($regionsToTest.Count)"
Write-Host "  Overall failed:         $failureCount / $($regionsToTest.Count)"

# Save detailed log
Write-Host ""
Write-Host "Saving detailed results to: $LogFile" -ForegroundColor Yellow
$results | ConvertTo-Json | Out-File -FilePath $LogFile -Encoding UTF8
Write-Host "Done!" -ForegroundColor Green
Write-Host ""

Write-Host "Saving markdown report to: $ReportFile" -ForegroundColor Yellow
Write-MarkdownReport `
    -TestResults $results `
    -OutputPath $ReportFile `
    -PlanSku $Sku `
    -SubscriptionId $Subscription `
    -StartedAt $timestamp `
    -SupportedRegionCount $($regionsToTest.Count) `
    -PostgresWasTested:$TestPostgres
Write-Host "Done!" -ForegroundColor Green
Write-Host ""

# Exit with success only if at least one region worked
if ($successCount -gt 0) {
    Write-Host "✓ At least one region available for F1 deployment!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "✗ No regions available for F1 deployment - consider B1 tier instead." -ForegroundColor Red
    exit 1
}
