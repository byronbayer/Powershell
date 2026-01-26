<#
.SYNOPSIS
    Clone and update Git repositories from Azure DevOps or GitHub.

.DESCRIPTION
    Unified script to clone new repositories and update existing ones from multiple
    Azure DevOps organisations or GitHub owners. Supports filtering, parallel processing,
    and both HTTPS and SSH authentication.

.PARAMETER connectionToken
    Personal Access Token for Azure DevOps authentication. Required for Azure DevOps.

.PARAMETER organisations
    Array of Azure DevOps organisation names to process. Required for Azure DevOps.

.PARAMETER IgnoreProjects
    Array of Azure DevOps project names to skip. Optional for Azure DevOps.

.PARAMETER includeProjects
    Array of Azure DevOps project names to include. If specified, only these projects are processed. Optional for Azure DevOps.

.PARAMETER owners
    Array of GitHub users or organisation names to process. Required for GitHub.

.PARAMETER IgnoreRepos
    Array of GitHub repository names to skip. Optional for GitHub.

.PARAMETER includeRepos
    Array of GitHub repository names to include. If specified, only these repositories are processed. Optional for GitHub.

.PARAMETER rootFolder
    Root directory where repositories will be cloned. Required for both platforms.

.PARAMETER fetchOnly
    If specified, only fetch changes without pulling. Useful for checking updates without merging.

.PARAMETER Parallel
    Enable parallel processing of repositories. Requires PowerShell 7+. Uses 5 concurrent operations.

.PARAMETER UseSSH
    Use SSH URLs instead of HTTPS for cloning. Requires SSH keys to be configured.

.PARAMETER SkipArchived
    Skip archived repositories. GitHub only.

.PARAMETER SkipForks
    Skip forked repositories. GitHub only.

.EXAMPLE
    Get-AllRepos -organisations @("contoso") -connectionToken "pat123" -rootFolder "C:\Dev"
    Clone and update all repositories from Azure DevOps organisation "contoso".

.EXAMPLE
    Get-AllRepos -owners @("octocat", "github") -rootFolder "C:\Dev" -SkipArchived -SkipForks
    Clone and update all non-archived, non-forked repositories from GitHub users/organisations.

.EXAMPLE
    Get-AllRepos -organisations @("contoso") -connectionToken "pat123" -rootFolder "C:\Dev" -includeProjects @("ProjectA", "ProjectB") -Parallel
    Clone only ProjectA and ProjectB from Azure DevOps using parallel processing.

.EXAMPLE
    Get-AllRepos -owners @("microsoft") -rootFolder "C:\Dev" -fetchOnly
    Fetch updates from all Microsoft GitHub repositories without pulling changes.

.LINK
    https://github.com/byronbayer/Powershell
#>

function Get-AllRepos {
    [CmdletBinding(DefaultParameterSetName = 'AzureDevOps')]
    param (
        # Azure DevOps specific parameters
        [Parameter(ParameterSetName = 'AzureDevOps', Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$connectionToken,
        
        [Parameter(ParameterSetName = 'AzureDevOps', Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string[]]$organisations,
        
        [Parameter(ParameterSetName = 'AzureDevOps')]
        [string[]]$IgnoreProjects,
        
        [Parameter(ParameterSetName = 'AzureDevOps')]
        [string[]]$includeProjects,
        
        # GitHub specific parameters
        [Parameter(ParameterSetName = 'GitHub', Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string[]]$owners,
        
        [Parameter(ParameterSetName = 'GitHub')]
        [string[]]$IgnoreRepos,
        
        [Parameter(ParameterSetName = 'GitHub')]
        [string[]]$includeRepos,
        
        [Parameter(ParameterSetName = 'GitHub')]
        [switch]$SkipArchived,
        
        [Parameter(ParameterSetName = 'GitHub')]
        [switch]$SkipForks,
        
        # Common parameters
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$rootFolder,
        
        [switch]$fetchOnly,
        
        [switch]$Parallel,
        
        [switch]$UseSSH
    )
    
    # Initialize error tracking
    $script:errors = @()
    
    # Validate git installation
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        throw "Git is not installed or not in PATH. Please install Git from https://git-scm.com/"
    }
    
    # Check PowerShell version for parallel processing
    if ($Parallel -and $PSVersionTable.PSVersion.Major -lt 7) {
        Write-Warning "Parallel processing requires PowerShell 7 or later. Current version: $($PSVersionTable.PSVersion). Falling back to sequential processing."
        $Parallel = $false
    }
    
    # Create root folder if it doesn't exist
    if (-not (Test-Path $rootFolder)) {
        New-Item -ItemType Directory -Path $rootFolder | Out-Null
    }
    
    # Determine platform
    $platform = $PSCmdlet.ParameterSetName
    
    Write-Host "Platform: $platform" -ForegroundColor Cyan
    Write-Host "Root folder: $rootFolder" -ForegroundColor Cyan
    Write-Host "Parallel processing: $Parallel" -ForegroundColor Cyan
    Write-Host ""
    
    # Process repositories based on platform
    switch ($platform) {
        'AzureDevOps' {
            Process-AzureDevOpsRepos -connectionToken $connectionToken `
                -organisations $organisations `
                -rootFolder $rootFolder `
                -IgnoreProjects $IgnoreProjects `
                -includeProjects $includeProjects `
                -fetchOnly:$fetchOnly `
                -Parallel:$Parallel `
                -UseSSH:$UseSSH
        }
        'GitHub' {
            Process-GitHubRepos -owners $owners `
                -rootFolder $rootFolder `
                -IgnoreRepos $IgnoreRepos `
                -includeRepos $includeRepos `
                -SkipArchived:$SkipArchived `
                -SkipForks:$SkipForks `
                -fetchOnly:$fetchOnly `
                -Parallel:$Parallel `
                -UseSSH:$UseSSH
        }
    }
    
    # Display error summary
    if ($script:errors.Count -gt 0) {
        Write-Host ""
        Write-Host "=== Error Summary ===" -ForegroundColor Red
        Write-Host "Total errors: $($script:errors.Count)" -ForegroundColor Red
        Write-Host ""
        foreach ($err in $script:errors) {
            Write-Host "❌ $($err.Repository): $($err.Message)" -ForegroundColor Red
        }
    } else {
        Write-Host ""
        Write-Host "✓ All operations completed successfully!" -ForegroundColor Green
    }
}

#region Helper Functions

function Invoke-AzureDevOpsApi {
    param (
        [Parameter(Mandatory)]
        [string]$Uri,
        
        [Parameter(Mandatory)]
        [string]$ConnectionToken
    )
    
    try {
        $base64AuthInfo = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes(":$ConnectionToken"))
        $headers = @{
            Authorization = "Basic $base64AuthInfo"
        }
        
        $response = Invoke-RestMethod -Uri $Uri -Method Get -Headers $headers -ErrorAction Stop
        return $response
    }
    catch {
        Write-Error "Azure DevOps API call failed: $($_.Exception.Message)"
        throw
    }
}

function Invoke-GitHubApiSmart {
    <#
    .SYNOPSIS
        Makes GitHub API calls using the best available authentication method.
    
    .DESCRIPTION
        Attempts authentication in this order:
        1. GitHub CLI (gh) if available and authenticated
        2. Unauthenticated API call (for public repos)
        
        This ensures the script works even without authentication while
        providing better rate limits when authentication is available.
    #>
    param (
        [Parameter(Mandatory)]
        [string]$Uri,
        
        [string]$Method = "GET"
    )
    
    # Method 1: Try GitHub CLI
    if (Get-Command gh -ErrorAction SilentlyContinue) {
        try {
            gh auth status 2>&1 | Out-Null
            if ($LASTEXITCODE -eq 0) {
                Write-Verbose "Using GitHub CLI authentication"
                
                # Convert full URL to API endpoint
                $endpoint = $Uri -replace "https://api\.github\.com/", ""
                
                # Suppress stderr and check for success
                $output = gh api $endpoint --method $Method 2>$null
                if ($LASTEXITCODE -eq 0 -and $output) {
                    $result = $output | ConvertFrom-Json
                    return $result
                }
                # If gh api failed, fall through to unauthenticated method
            }
        }
        catch {
            Write-Verbose "GitHub CLI authentication failed, falling back to unauthenticated..."
        }
    }
    
    # Method 2: Unauthenticated call (fallback)
    Write-Verbose "Using unauthenticated API call (rate limit: 60/hour)"
    try {
        $headers = @{
            Accept = "application/vnd.github+json"
        }
        
        $response = Invoke-RestMethod -Uri $Uri -Method $Method -Headers $headers -ErrorAction Stop
        return $response
    }
    catch {
        $statusCode = $_.Exception.Response.StatusCode.Value__
        if ($statusCode -eq 403) {
            Write-Warning "GitHub API rate limit exceeded. Please authenticate using 'gh auth login' for higher limits (5000/hour vs 60/hour)."
            Write-Warning "Install GitHub CLI from: https://cli.github.com/"
        }
        throw
    }
}

function Get-GitHubReposWithPagination {
    param (
        [Parameter(Mandatory)]
        [string]$Owner,
        
        [switch]$SkipArchived,
        
        [switch]$SkipForks
    )
    
    $allRepos = @()
    $page = 1
    $perPage = 100
    
    # Try to determine if owner is an org or user
    try {
        $orgCheck = Invoke-GitHubApiSmart -Uri "https://api.github.com/orgs/$Owner"
        $endpoint = "orgs"
    }
    catch {
        $endpoint = "users"
    }
    
    do {
        $uri = "https://api.github.com/$endpoint/$Owner/repos?per_page=$perPage&page=$page&type=all"
        
        try {
            $repos = Invoke-GitHubApiSmart -Uri $uri
            
            # Filter repositories
            $filteredRepos = $repos | Where-Object {
                $include = $true
                
                if ($SkipArchived -and $_.archived) {
                    Write-Verbose "Skipping archived repository: $($_.name)"
                    $include = $false
                }
                
                if ($SkipForks -and $_.fork) {
                    Write-Verbose "Skipping forked repository: $($_.name)"
                    $include = $false
                }
                
                $include
            }
            
            $allRepos += $filteredRepos
            $page++
        }
        catch {
            Write-Error "Failed to fetch repositories for $Owner (page $page): $($_.Exception.Message)"
            break
        }
    } while ($repos.Count -eq $perPage)
    
    return $allRepos
}

function Update-GitRepository {
    param (
        [Parameter(Mandatory)]
        [string]$RepoPath,
        
        [Parameter(Mandatory)]
        [string]$RepoName,
        
        [Parameter(Mandatory)]
        [string]$DefaultBranch,
        
        [switch]$FetchOnly
    )
    
    try {
        Write-Host "  Repository exists. Fetching..." -ForegroundColor Yellow
        Push-Location $RepoPath
        
        git fetch --prune 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0) {
            throw "Git fetch failed with exit code $LASTEXITCODE"
        }
        
        if (-not $FetchOnly) {
            # Check if repository has any commits
            git rev-parse --verify HEAD 2>&1 | Out-Null
            $hasCommits = $LASTEXITCODE -eq 0
            
            if (-not $hasCommits) {
                Write-Host "  ⚠ Repository is empty (no commits yet). Skipping checkout/pull." -ForegroundColor DarkYellow
                Pop-Location
                return
            }
            
            # Check current branch
            $currentBranch = git rev-parse --abbrev-ref HEAD 2>&1
            
            if ($currentBranch -ne $DefaultBranch) {
                Write-Host "  Switching to branch $DefaultBranch..." -ForegroundColor Yellow
                git checkout $DefaultBranch 2>&1 | Out-Null
                if ($LASTEXITCODE -ne 0) {
                    throw "Git checkout failed with exit code $LASTEXITCODE. You may have uncommitted changes."
                }
            }
            else {
                Write-Host "  Already on $DefaultBranch. Pulling latest changes..." -ForegroundColor Yellow
            }
            
            # Retry logic for git pull
            $maxAttempts = 5
            $attempt = 1
            $success = $false
            
            while ($attempt -le $maxAttempts) {
                git pull 2>&1 | Out-Null
                if ($LASTEXITCODE -eq 0) {
                    Write-Host "  ✓ Git pull successful!" -ForegroundColor Green
                    $success = $true
                    break
                }
                else {
                    Write-Warning "  Attempt $attempt failed... retrying in 1 second"
                    Start-Sleep -Seconds 1
                    $attempt++
                }
            }
            
            if (-not $success) {
                throw "Maximum pull attempts ($maxAttempts) reached"
            }
        }
        
        Pop-Location
    }
    catch {
        Pop-Location
        $script:errors += @{
            Repository = $RepoName
            Message = $_.Exception.Message
        }
        Write-Warning "  Failed to update repository: $($_.Exception.Message)"
    }
}

function Clone-GitRepository {
    param (
        [Parameter(Mandatory)]
        [string]$CloneUrl,
        
        [Parameter(Mandatory)]
        [string]$RepoName,
        
        [Parameter(Mandatory)]
        [string]$DestinationPath
    )
    
    try {
        Write-Host "  Repository does not exist. Cloning..." -ForegroundColor Green
        
        git clone $CloneUrl $DestinationPath 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0) {
            throw "Git clone failed with exit code $LASTEXITCODE"
        }
        
        Write-Host "  ✓ Clone successful!" -ForegroundColor Green
    }
    catch {
        $script:errors += @{
            Repository = $RepoName
            Message = $_.Exception.Message
        }
        Write-Warning "  Failed to clone repository: $($_.Exception.Message)"
    }
}

function Process-AzureDevOpsRepos {
    param (
        [string]$connectionToken,
        [string[]]$organisations,
        [string]$rootFolder,
        [string[]]$IgnoreProjects,
        [string[]]$includeProjects,
        [switch]$fetchOnly,
        [switch]$Parallel,
        [switch]$UseSSH
    )
    
    foreach ($organisation in $organisations) {
        Write-Host "Organisation: $organisation" -ForegroundColor Cyan
        
        Set-Location $rootFolder
        
        # Get all projects
        $projectUrl = "https://dev.azure.com/$organisation/_apis/projects?api-version=7.2-preview.4"
        try {
            $Projects = Invoke-AzureDevOpsApi -Uri $projectUrl -ConnectionToken $connectionToken
        }
        catch {
            Write-Error "Failed to fetch projects for organisation '$organisation': $($_.Exception.Message)"
            continue
        }
        
        $projectCount = 0
        $totalProjects = $Projects.value.Count
        
        foreach ($project in $Projects.value) {
            $projectCount++
            
            # Filter projects
            if ($IgnoreProjects -contains $project.name) {
                Write-Host "  Ignoring project: $($project.name)" -ForegroundColor DarkGray
                continue
            }
            
            if ($includeProjects -and $includeProjects.Count -gt 0 -and $includeProjects -notcontains $project.name) {
                Write-Host "  Skipping project not in include list: $($project.name)" -ForegroundColor DarkGray
                continue
            }
            
            $projectName = $project.name
            $projectId = $project.id
            
            Write-Progress -Activity "Processing Azure DevOps" `
                -Status "Organisation: $organisation | Project: $projectName" `
                -PercentComplete (($projectCount / $totalProjects) * 100)
            
            Write-Host "  Project: $projectName" -ForegroundColor White
            
            # Check if Git is enabled
            $projectPropertiesUrl = "https://dev.azure.com/$organisation/_apis/projects/$projectId/properties?keys=System.SourceControlGitEnabled&api-version=7.1-preview.1"
            try {
                $projectProperties = Invoke-AzureDevOpsApi -Uri $projectPropertiesUrl -ConnectionToken $connectionToken
                $gitEnabled = ($projectProperties.value | Where-Object { $_.name -eq "System.SourceControlGitEnabled" }).value
                
                if ($gitEnabled -eq $false) {
                    Write-Host "    Git is not enabled for this project" -ForegroundColor DarkGray
                    continue
                }
            }
            catch {
                Write-Warning "    Failed to check Git status: $($_.Exception.Message)"
                continue
            }
            
            # Get repositories
            $repoUrl = "https://dev.azure.com/$organisation/$projectName/_apis/git/repositories?api-version=7.2-preview.1"
            try {
                $Repos = Invoke-AzureDevOpsApi -Uri $repoUrl -ConnectionToken $connectionToken
            }
            catch {
                Write-Warning "    Failed to fetch repositories: $($_.Exception.Message)"
                continue
            }
            
            # Create project directory
            $location = Join-Path $rootFolder $organisation $projectName
            if (-not (Test-Path $location)) {
                New-Item -ItemType Directory -Path $location | Out-Null
            }
            
            Set-Location $location
            
            # Process repositories
            $repoList = $Repos.value
            $repoCount = 0
            $totalRepos = $repoList.Count
            
            $processRepo = {
                param($repo, $location, $fetchOnly, $UseSSH)
                
                $repoName = $repo.name
                Write-Host "    Repository: $repoName" -ForegroundColor White
                
                # Extract default branch
                $defaultBranch = $repo.defaultBranch -replace '^refs/heads/', ''
                
                # Select clone URL
                $cloneUrl = if ($UseSSH) { $repo.sshUrl } else { $repo.remoteUrl }
                
                $repoPath = Join-Path $location $repoName
                
                if (Test-Path $repoPath) {
                    Update-GitRepository -RepoPath $repoPath `
                        -RepoName $repoName `
                        -DefaultBranch $defaultBranch `
                        -FetchOnly:$fetchOnly
                }
                else {
                    Clone-GitRepository -CloneUrl $cloneUrl `
                        -RepoName $repoName `
                        -DestinationPath $repoPath
                }
            }
            
            if ($Parallel) {
                $repoList | ForEach-Object -Parallel {
                    $repo = $_
                    & $using:processRepo $repo $using:location $using:fetchOnly $using:UseSSH
                } -ThrottleLimit 5
            }
            else {
                foreach ($repo in $repoList) {
                    $repoCount++
                    Write-Progress -Activity "Processing Repositories" `
                        -Status "Project: $projectName | Repo: $($repo.name)" `
                        -PercentComplete (($repoCount / $totalRepos) * 100)
                    
                    & $processRepo $repo $location $fetchOnly $UseSSH
                }
            }
        }
        
        Write-Progress -Activity "Processing Azure DevOps" -Completed
    }
}

function Process-GitHubRepos {
    param (
        [string[]]$owners,
        [string]$rootFolder,
        [string[]]$IgnoreRepos,
        [string[]]$includeRepos,
        [switch]$SkipArchived,
        [switch]$SkipForks,
        [switch]$fetchOnly,
        [switch]$Parallel,
        [switch]$UseSSH
    )
    
    foreach ($owner in $owners) {
        Write-Host "Owner: $owner" -ForegroundColor Cyan
        
        Set-Location $rootFolder
        
        # Get all repositories with pagination
        try {
            $allRepos = Get-GitHubReposWithPagination -Owner $owner `
                -SkipArchived:$SkipArchived `
                -SkipForks:$SkipForks
        }
        catch {
            Write-Error "Failed to fetch repositories for owner '$owner': $($_.Exception.Message)"
            continue
        }
        
        # Filter repositories
        $filteredRepos = $allRepos | Where-Object {
            $include = $true
            
            if ($IgnoreRepos -contains $_.name) {
                Write-Host "  Ignoring repository: $($_.name)" -ForegroundColor DarkGray
                $include = $false
            }
            
            if ($includeRepos -and $includeRepos.Count -gt 0 -and $includeRepos -notcontains $_.name) {
                Write-Host "  Skipping repository not in include list: $($_.name)" -ForegroundColor DarkGray
                $include = $false
            }
            
            $include
        }
        
        # Create owner directory
        $location = Join-Path $rootFolder $owner
        if (-not (Test-Path $location)) {
            New-Item -ItemType Directory -Path $location | Out-Null
        }
        
        Set-Location $location
        
        # Process repositories
        $repoCount = 0
        $totalRepos = $filteredRepos.Count
        
        Write-Host "  Found $totalRepos repositories" -ForegroundColor White
        
        $processRepo = {
            param($repo, $location, $fetchOnly, $UseSSH)
            
            $repoName = $repo.name
            Write-Host "  Repository: $repoName" -ForegroundColor White
            
            # Extract default branch
            $defaultBranch = $repo.default_branch
            
            # Select clone URL
            $cloneUrl = if ($UseSSH) { $repo.ssh_url } else { $repo.clone_url }
            
            $repoPath = Join-Path $location $repoName
            
            if (Test-Path $repoPath) {
                Update-GitRepository -RepoPath $repoPath `
                    -RepoName $repoName `
                    -DefaultBranch $defaultBranch `
                    -FetchOnly:$fetchOnly
            }
            else {
                Clone-GitRepository -CloneUrl $cloneUrl `
                    -RepoName $repoName `
                    -DestinationPath $repoPath
            }
        }
        
        if ($Parallel) {
            $filteredRepos | ForEach-Object -Parallel {
                $repo = $_
                & $using:processRepo $repo $using:location $using:fetchOnly $using:UseSSH
            } -ThrottleLimit 5
        }
        else {
            foreach ($repo in $filteredRepos) {
                $repoCount++
                Write-Progress -Activity "Processing GitHub Repositories" `
                    -Status "Owner: $owner | Repo: $($repo.name)" `
                    -PercentComplete (($repoCount / $totalRepos) * 100)
                
                & $processRepo $repo $location $fetchOnly $UseSSH
            }
        }
        
        Write-Progress -Activity "Processing GitHub Repositories" -Completed
    }
}

#endregion

# Example usage (uncomment to use):

# Azure DevOps
# Get-AllRepos -organisations @("org1") -connectionToken "<your-pat-token>" -rootFolder "C:\Dev" -includeProjects @("Project1", "Project2")

# GitHub (will use gh CLI if authenticated, or unauthenticated API for public repos)
Get-AllRepos -owners @("byronbayer") -rootFolder "C:\Dev" -SkipArchived -SkipForks

# GitHub with parallel processing (requires PowerShell 7+)
# Get-AllRepos -owners @("microsoft") -rootFolder "C:\Dev" -Parallel

# Azure DevOps with SSH
# Get-AllRepos -organisations @("org1") -connectionToken "<your-pat-token>" -rootFolder "C:\Dev" -UseSSH
