Clear-Host

$RepoBackupFolder = 'C:\Dev\RepoBackups'

if (-not (Test-Path $RepoBackupFolder)) {
    New-Item -ItemType Directory -Path $RepoBackupFolder
}
else {
    Remove-Item -Path $RepoBackupFolder -Recurse -Force -ErrorAction SilentlyContinue
    New-Item -ItemType Directory -Path $RepoBackupFolder -ErrorAction SilentlyContinue
}
Set-Location $RepoBackupFolder

function Move-Repo {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]
        $repoFrom,
        [Parameter()]
        [string]
        $repoTo
    )
    $folder = $repoFrom.Substring($repoFrom.LastIndexOf('/') + 1, ($repoFrom.Length - $repoFrom.LastIndexOf('/') - 1))
    Remove-Item -Path ".\$folder.git" -Recurse -Force -ErrorAction SilentlyContinue
    git clone --mirror $repoFrom
    Set-Location ".\$folder.git"
    git push --mirror $repoTo --force
    Set-Location $RepoBackupFolder
}

function Lock-All-Branches {
    [CmdletBinding()]
    param (    
        [Parameter()]
        [string]
        $organisation,
        [Parameter()]
        [string]
        $project,
        [Parameter()]
        [string]
        $repositoryId,
        [Parameter()]
        [string]
        $connectionToken
    )   

    # Get all branches in the repository
    $url = "https://dev.azure.com/$organisation/$project/_apis/git/repositories/$repositoryId/refs?api-version=6.0"
    $base64AuthInfo = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes(":$($connectionToken)"))
    $branches = Invoke-RestMethod -Uri $Url -Headers @{Authorization = ("Basic {0}" -f $base64AuthInfo) }

    # Lock each branch
    foreach ($branch in $branches.value) {
        $branchName = $branch.name
        #remove the "refs/" prefix
        $branchName = $branchName.Substring(5)    
        $url = "https://dev.azure.com/$organisation/$project/_apis/git/repositories/$repositoryId/refs?filter=$($branchName)&api-version=6.0"
        $body = @{
            isLocked = $true
        } | ConvertTo-Json

        Invoke-RestMethod -Uri $url -Method Patch -Headers @{Authorization = ("Basic {0}" -f $base64AuthInfo) } -ContentType "application/json" -Body $body
        Write-Host "Branch '$branchName' locked."
    }
}

function Move-Repos {
    [CmdletBinding()]
    param (
        [Parameter()]        
        $OrganisationFrom,
        [Parameter()]        
        $OrganisationTo,
        [Parameter()]        
        $ProjectFrom,
        [Parameter()]        
        $ProjectTo,
        [Parameter()]        
        $connectionToken        
    )
    $base64AuthInfo = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes(":$($connectionToken)"))
    $repoUrl = "https://dev.azure.com/$OrganisationFrom/$ProjectFrom/_apis/git/repositories?api-version=7.2-preview.1"
    $Repos = Invoke-RestMethod -Uri $repoUrl -Method Get -Headers @{Authorization = ("Basic {0}" -f $base64AuthInfo) }
    
    $Repos.value | ForEach-Object {
        $repositoryName = $_.name
        $remoteName = $_.remoteUrl
        $repoTo = $remoteName.Replace($OrganisationFrom, $OrganisationTo).Replace($ProjectFrom, $ProjectTo)
        Write-Host "Repository Name: $repositoryName"
        Write-Host "Repository From: $remoteName"
        Write-Host "Repository To: $repoTo"
                
        # check if repository exists
        $repoUrl = "https://dev.azure.com/$OrganisationTo/$ProjectTo/_apis/git/repositories/$($repositoryName)?api-version=4.1"
        $repo = $null
        $repo = Invoke-RestMethod -Uri $repoUrl -Method Get -Headers @{Authorization = ("Basic {0}" -f $base64AuthInfo) }

        if ($null -ne $repo) {
            Write-Host "Repository '$repositoryName' already exists."
        }
        else {
            # create repository
            $apiUrl = "https://dev.azure.com/$OrganisationTo/$ProjectTo/_apis/git/repositories?api-version=4.1"
            $jsonPayload = @{
                name    = $repositoryName
                project = @{
                    id = '214544fc-d970-4670-beb7-c3eff3800ed2'
                }
            } | ConvertTo-Json
            $response = Invoke-WebRequest -Uri $apiUrl -Method Post -Headers @{
                Authorization  = ("Basic {0}" -f $base64AuthInfo)
                "Content-Type" = "application/json"
            } -Body $jsonPayload
            if ($response.StatusCode -eq 201) {
                Write-Host "Repository '$repositoryName' created successfully."                
            }
            else {
                Write-Host "Error creating repository. Status code: $($response.StatusCode)"
                Write-Host "Response content: $($response.Content)"
            }
            Move-Repo -repoFrom $remoteName -repoTo $repoTo
            Lock-All-Branches -Organisation $OrganisationFrom -Project $ProjectFrom -Repository $repositoryName -connectionToken $connectionToken
        }
    }
}

$organisationFrom = ''
$organisationTo = ''
$projectfrom = ''
$projectTo = ''

Move-Repos -OrganisationFrom $organisationFrom `
    -OrganisationTo $organisationTo `
    -ProjectFrom $projectfrom `
    -ProjectTo $projectTo `
    -connectionToken ""
