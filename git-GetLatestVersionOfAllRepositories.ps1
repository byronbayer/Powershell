function Get-AllRepos {
    
    [CmdletBinding()]
    param (      
        
        [Parameter()]      
        [string]
        $connectionToken,
        [Parameter()]
        [String]
        $rootFolder,
        [Parameter()]
        [String[]]
        $organisations,
        [Parameter()]
        [switch]
        $fetchOnly,
        [Parameter()]
        [String[]]
        $IgnoreProjects,
        [Parameter()]
        [String[]]
        $includeProjects
    )

    $base64AuthInfo = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes(":$($connectionToken)"))
    
    if (-not (Test-Path $rootFolder)) {
        New-Item -ItemType Directory -Path $rootFolder
    }
    
    foreach ($organisation in $organisations) {
        Set-Location $rootFolder
        $projectUrl = "https://dev.azure.com/$organisation/_apis/projects?api-version=7.2-preview.4"    
        $Projects = Invoke-RestMethod -Uri $projectUrl -Method Get -Headers @{Authorization = ("Basic {0}" -f $base64AuthInfo) }    
        foreach ($project in $Projects.value) {
            if ($IgnoreProjects -contains $project.name) {
                Write-Host "Ignoring project: $($project.name)"
                continue
            }
            if ($includeProjects -and $includeProjects.Count -gt 0 -and $includeProjects -notcontains $project.name) {
                Write-Host "Skipping project not in include list: $($project.name)"
                continue
            }
            $projectName = $project.name
            $projectId = $project.id
            Write-Host "Project Name: $projectName"
            $projectPropertiesUrl = "https://dev.azure.com/$organisation/_apis/projects/$projectId/properties?keys=System.SourceControlGitEnabled&api-version=7.1-preview.1"
            $projectProperties = Invoke-RestMethod -Uri $projectPropertiesUrl -Method Get -Headers @{Authorization = ("Basic {0}" -f $base64AuthInfo) }
            $gitEnabled = ($projectProperties.value | Where-Object { $_.name -eq "System.SourceControlGitEnabled" }).value
            if ( $gitEnabled -eq $false) {
                Write-Host "Git is not enabled for this project"
                continue
            }

            $repoUrl = "https://dev.azure.com/$organisation/$projectName/_apis/git/repositories?api-version=7.2-preview.1"
            $Repos = Invoke-RestMethod -Uri $repoUrl -Method Get -Headers @{Authorization = ("Basic {0}" -f $base64AuthInfo) }
            $location = "$rootFolder\$organisation\$projectName"
            if (-not (Test-Path $location)) {     
                New-Item -ItemType Directory -Path $location
            }
            Set-Location $location
            $Repos.value | ForEach-Object {
                $repoName = $_.name
                Write-Host "Repository Name: $repoName"
                        
                if (Test-Path $repoName) {
                    Write-Host "Repository exists. Fetching..."
                    Set-Location $repoName
                    git fetch --prune
                    if (-not $fetchOnly) {
                        if ($_.defaultBranch -eq "refs/heads/main") {
                            $defaultBranch = "main"
                        }
                        else {
                            $defaultBranch = $null
                        }
                        Write-Host "Pulling latest changes from $defaultBranch"
                        git checkout $defaultBranch
                        $maxAttempts = 5
                        $attempt = 1
                        while ($attempt -le $maxAttempts) {
                            try {
                                git pull --force
                                Write-Output "Git pull successful!"
                                break
                            }
                            catch {
                                Write-Output "Attempt $attempt failed... retrying in 1 seconds"
                                Start-Sleep -Seconds 1
                                $attempt++
                            }
                        }

                        if ($attempt -gt $maxAttempts) {
                            Write-Output "Maximum attempts reached. Exiting."
                            exit 1
                        }
                    }
                    Set-Location ..
                }
                else {
                    Write-Host "Repository does not exist. Cloning..."
                    git clone $_.remoteUrl $repoName
                }
            }
        }
    }
}
$rootFolder = "C:\Dev"
Get-AllRepos -connectionToken "" `
    -rootFolder $rootFolder `
    -organisations @("org1") `
    -includeProjects @("proj1", "proj2" )
