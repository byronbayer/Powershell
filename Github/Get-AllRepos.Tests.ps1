BeforeAll {
    # Load functions without executing the example call at the bottom of the script.
    $scriptPath = Join-Path $PSScriptRoot 'Get-AllRepos.ps1'
    $scriptContent = Get-Content -Path $scriptPath -Raw
    $scriptContent = $scriptContent -replace '(?ms)\r?\n# Example usage \(uncomment to use\):.*$', ''

    . ([ScriptBlock]::Create($scriptContent))
}

Describe 'Get-AllRepos' {

    Context 'Parameter contract' {

        It 'requires owners and rootFolder' {
            $command = Get-Command Get-AllRepos

            $command.Parameters['owners'].Attributes.Mandatory | Should -Contain $true
            $command.Parameters['rootFolder'].Attributes.Mandatory | Should -Contain $true
        }

        It 'does not expose Azure DevOps parameters' {
            $command = Get-Command Get-AllRepos

            $command.Parameters.ContainsKey('connectionToken') | Should -BeFalse
            $command.Parameters.ContainsKey('organisations') | Should -BeFalse
            $command.Parameters.ContainsKey('IgnoreProjects') | Should -BeFalse
            $command.Parameters.ContainsKey('includeProjects') | Should -BeFalse
        }

        It 'exposes GitHub-specific filters and switches' {
            $command = Get-Command Get-AllRepos

            $command.Parameters.ContainsKey('IgnoreRepos') | Should -BeTrue
            $command.Parameters.ContainsKey('includeRepos') | Should -BeTrue
            $command.Parameters.ContainsKey('SkipArchived') | Should -BeTrue
            $command.Parameters.ContainsKey('SkipForks') | Should -BeTrue
            $command.Parameters.ContainsKey('UseSSH') | Should -BeTrue
            $command.Parameters.ContainsKey('Parallel') | Should -BeTrue
            $command.Parameters.ContainsKey('fetchOnly') | Should -BeTrue
        }
    }

    Context 'Main execution flow' {

        BeforeEach {
            Mock Get-Command { @{ Name = 'git' } } -ParameterFilter { $Name -eq 'git' }
            Mock Test-Path { $true }
            Mock Process-GitHubRepos { }
            Mock Write-Host { }
        }

        It 'calls Process-GitHubRepos with provided arguments' {
            Get-AllRepos -owners @('owner1') -rootFolder 'TestDrive:\repos' -SkipArchived -SkipForks -fetchOnly

            Should -Invoke Process-GitHubRepos -Times 1 -ParameterFilter {
                $owners -contains 'owner1' -and
                $rootFolder -eq 'TestDrive:\repos' -and
                $SkipArchived -and
                $SkipForks -and
                $fetchOnly
            }
        }

        It 'throws when git is missing' {
            Mock Get-Command { $null } -ParameterFilter { $Name -eq 'git' }

            { Get-AllRepos -owners @('owner1') -rootFolder 'TestDrive:\repos' } | Should -Throw '*Git is not installed*'
        }
    }
}

Describe 'Invoke-GitHubApiSmart' {

    Context 'Authentication strategy' {

        It 'uses gh when available and authenticated' {
            Mock Get-Command { @{ Name = 'gh' } } -ParameterFilter { $Name -eq 'gh' }
            Mock gh {
                if ($args -contains 'status') {
                    $global:LASTEXITCODE = 0
                    return
                }

                $global:LASTEXITCODE = 0
                return '{"name":"repo"}'
            }
            Mock Write-Verbose { }

            $result = Invoke-GitHubApiSmart -Uri 'https://api.github.com/repos/test/repo'

            $result.name | Should -Be 'repo'
            Should -Invoke gh -Times 1 -ParameterFilter { $args -contains 'status' }
            Should -Invoke gh -Times 1 -ParameterFilter { $args -contains 'api' }
        }

        It 'falls back to Invoke-RestMethod when gh is unavailable' {
            Mock Get-Command { $null } -ParameterFilter { $Name -eq 'gh' }
            Mock Invoke-RestMethod { @{ name = 'repo' } }
            Mock Write-Verbose { }

            $result = Invoke-GitHubApiSmart -Uri 'https://api.github.com/repos/test/repo'

            $result.name | Should -Be 'repo'
            Should -Invoke Invoke-RestMethod -Times 1
        }
    }
}

Describe 'Get-GitHubReposWithPagination' {

    It 'falls back to user endpoint when org lookup fails' {
        Mock Invoke-GitHubApiSmart {
            param($Uri)

            if ($Uri -eq 'https://api.github.com/orgs/testuser') {
                throw 'Not an org'
            }

            return @()
        }

        Get-GitHubReposWithPagination -Owner 'testuser'

        Should -Invoke Invoke-GitHubApiSmart -Times 1 -ParameterFilter {
            $Uri -like 'https://api.github.com/users/testuser/repos*'
        }
    }

    It 'filters archived and forked repositories when switches are set' {
        Mock Invoke-GitHubApiSmart {
            param($Uri)

            if ($Uri -eq 'https://api.github.com/orgs/testorg') {
                return @{ type = 'Organization' }
            }

            return @(
                [PSCustomObject]@{ name = 'repo1'; archived = $false; fork = $false }
                [PSCustomObject]@{ name = 'repo2'; archived = $true; fork = $false }
                [PSCustomObject]@{ name = 'repo3'; archived = $false; fork = $true }
            )
        }
        Mock Write-Verbose { }

        $repos = Get-GitHubReposWithPagination -Owner 'testorg' -SkipArchived -SkipForks

        $repos.Count | Should -Be 1
        $repos[0].name | Should -Be 'repo1'
    }
}

Describe 'Process-GitHubRepos' {

    BeforeEach {
        Mock Set-Location { }
        Mock New-Item { }
        Mock Test-Path {
            param($Path)
            return $Path -like '*repo1'
        }
        Mock Write-Host { }
        Mock Write-Progress { }
        Mock Update-GitRepository { }
        Mock Clone-GitRepository { }

        Mock Get-GitHubReposWithPagination {
            @(
                [PSCustomObject]@{
                    name = 'repo1'
                    default_branch = 'main'
                    clone_url = 'https://github.com/acme/repo1.git'
                    ssh_url = 'git@github.com:acme/repo1.git'
                }
                [PSCustomObject]@{
                    name = 'repo2'
                    default_branch = 'main'
                    clone_url = 'https://github.com/acme/repo2.git'
                    ssh_url = 'git@github.com:acme/repo2.git'
                }
                [PSCustomObject]@{
                    name = 'repo3'
                    default_branch = 'develop'
                    clone_url = 'https://github.com/acme/repo3.git'
                    ssh_url = 'git@github.com:acme/repo3.git'
                }
            )
        }
    }

    It 'applies include and ignore filters' {
        Process-GitHubRepos -owners @('acme') -rootFolder 'TestDrive:\repos' -includeRepos @('repo1', 'repo2') -IgnoreRepos @('repo2')

        Should -Invoke Update-GitRepository -Times 1 -ParameterFilter { $RepoName -eq 'repo1' }
        Should -Invoke Clone-GitRepository -Times 0 -ParameterFilter { $RepoName -eq 'repo2' }
        Should -Invoke Clone-GitRepository -Times 0 -ParameterFilter { $RepoName -eq 'repo3' }
    }

    It 'applies wildcard include and ignore filters' {
        Mock Test-Path { $false }

        Process-GitHubRepos -owners @('acme') -rootFolder 'TestDrive:\repos' -includeRepos @('repo*') -IgnoreRepos @('repo2*')

        Should -Invoke Clone-GitRepository -Times 1 -ParameterFilter { $RepoName -eq 'repo1' }
        Should -Invoke Clone-GitRepository -Times 0 -ParameterFilter { $RepoName -eq 'repo2' }
        Should -Invoke Clone-GitRepository -Times 1 -ParameterFilter { $RepoName -eq 'repo3' }
    }

    It 'processes only 2 repos when 3 are available and filter matches 2' {
        Mock Test-Path { $false }

        Process-GitHubRepos -owners @('acme') -rootFolder 'TestDrive:\repos' -includeRepos @('repo1', 'repo3')

        # 3 repos are returned by the mock; include filter should allow only repo1 and repo3.
        Should -Invoke Clone-GitRepository -Times 2
        Should -Invoke Clone-GitRepository -Times 1 -ParameterFilter { $RepoName -eq 'repo1' }
        Should -Invoke Clone-GitRepository -Times 0 -ParameterFilter { $RepoName -eq 'repo2' }
        Should -Invoke Clone-GitRepository -Times 1 -ParameterFilter { $RepoName -eq 'repo3' }
    }

    
    It 'processes only 2 repos when 3 are available and filter matches 2' {
        Mock Test-Path { $false }

        Process-GitHubRepos -owners @('acme') -rootFolder 'TestDrive:\repos' -includeRepos @('repo*')

        # 3 repos are returned by the mock; include filter should allow only repo1 and repo3.
        Should -Invoke Clone-GitRepository -Times 2
        Should -Invoke Clone-GitRepository -Times 1 -ParameterFilter { $RepoName -eq 'repo1' }
        Should -Invoke Clone-GitRepository -Times 0 -ParameterFilter { $RepoName -eq 'repa2' }
        Should -Invoke Clone-GitRepository -Times 1 -ParameterFilter { $RepoName -eq 'repo3' }
    }

    It 'uses ssh_url when UseSSH is set' {
        Mock Test-Path { $false }

        Process-GitHubRepos -owners @('acme') -rootFolder 'TestDrive:\repos' -includeRepos @('repo3') -UseSSH

        Should -Invoke Clone-GitRepository -Times 1 -ParameterFilter {
            $RepoName -eq 'repo3' -and $CloneUrl -eq 'git@github.com:acme/repo3.git'
        }
    }
}

Describe 'Update-GitRepository' {

    BeforeEach {
        $script:errors = @()
        Mock Push-Location { }
        Mock Pop-Location { }
        Mock Write-Host { }
        Mock Write-Warning { }
    }

    It 'does not pull when FetchOnly is set' {
        Mock git {
            if ($args[0] -eq 'fetch') {
                $global:LASTEXITCODE = 0
            }
        }

        Update-GitRepository -RepoPath 'TestDrive:\repo' -RepoName 'repo' -DefaultBranch 'main' -FetchOnly

        Should -Invoke git -Times 1 -ParameterFilter { $args[0] -eq 'fetch' -and $args -contains '--prune' }
        Should -Invoke git -Times 0 -ParameterFilter { $args[0] -eq 'pull' }
    }

    It 'tracks errors when fetch fails' {
        Mock git {
            if ($args[0] -eq 'fetch') {
                $global:LASTEXITCODE = 1
            }
        }

        Update-GitRepository -RepoPath 'TestDrive:\repo' -RepoName 'repo' -DefaultBranch 'main'

        $script:errors.Count | Should -Be 1
        $script:errors[0].Repository | Should -Be 'repo'
    }
}

Describe 'Clone-GitRepository' {

    BeforeEach {
        $script:errors = @()
        Mock Write-Host { }
        Mock Write-Warning { }
    }

    It 'calls git clone with URL and destination' {
        Mock git {
            param($command, $url, $destination)
            $global:LASTEXITCODE = 0

            $command | Should -Be 'clone'
            $url | Should -Be 'https://github.com/acme/repo.git'
            $destination | Should -Be 'TestDrive:\repo'
        }

        Clone-GitRepository -CloneUrl 'https://github.com/acme/repo.git' -RepoName 'repo' -DestinationPath 'TestDrive:\repo'
    }

    It 'adds to error tracking when clone fails' {
        Mock git { $global:LASTEXITCODE = 1 }

        Clone-GitRepository -CloneUrl 'https://github.com/acme/repo.git' -RepoName 'repo' -DestinationPath 'TestDrive:\repo'

        $script:errors.Count | Should -Be 1
        $script:errors[0].Repository | Should -Be 'repo'
    }
}
