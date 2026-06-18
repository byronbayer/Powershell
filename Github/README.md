# GitHub PowerShell Scripts

PowerShell scripts for managing GitHub repositories in bulk.

## Scripts

### [Get-AllRepos.ps1](Get-AllRepos.ps1)

Clones new repositories and pulls updates for existing ones across one or more GitHub users or organisations.

**Authentication** — uses GitHub CLI (`gh`) when available and authenticated (5,000 req/hour). Falls back to unauthenticated API calls for public repos (60 req/hour).

**Requirements**

- Git
- PowerShell 5.1+ (7+ required for `-Parallel`)
- [GitHub CLI](https://cli.github.com/) (optional, recommended)

**Parameters**

| Parameter | Type | Required | Description |
|---|---|---|---|
| `owners` | `string[]` | Yes | GitHub usernames or organisation names to process |
| `rootFolder` | `string` | Yes | Root directory where repos are cloned |
| `IgnoreRepos` | `string[]` | No | Repo names or wildcard patterns to skip |
| `includeRepos` | `string[]` | No | Repo names or wildcard patterns to include (all others skipped) |
| `SkipArchived` | `switch` | No | Skip archived repositories |
| `SkipForks` | `switch` | No | Skip forked repositories |
| `fetchOnly` | `switch` | No | Fetch only — do not pull or switch branches |
| `Parallel` | `switch` | No | Process repos concurrently (5 at a time); requires PS 7+ |
| `UseSSH` | `switch` | No | Clone using SSH URLs instead of HTTPS |

**Examples**

```powershell
# Clone/update all non-archived, non-forked repos from two GitHub accounts
Get-AllRepos -owners @("myuser", "myorg") -rootFolder "C:\Dev" -SkipArchived -SkipForks

# Fetch updates only (no pull) in parallel
Get-AllRepos -owners @("microsoft") -rootFolder "C:\Dev" -fetchOnly -Parallel

# Only process repos matching a pattern, using SSH
Get-AllRepos -owners @("myorg") -rootFolder "C:\Dev" -includeRepos @("service-*") -UseSSH
```

Repos are organised under `<rootFolder>\<owner>\<repo-name>`. The script switches each repo to its default branch before pulling and retries pulls up to 5 times on failure.

---

### [Get-AllRepos.Tests.ps1](Get-AllRepos.Tests.ps1)

[Pester](https://pester.dev/) test suite for `Get-AllRepos.ps1`. Covers parameter contracts, authentication fallback, pagination, filtering, and git operation error handling.

**Run tests**

```powershell
Invoke-Pester .\Get-AllRepos.Tests.ps1
```
