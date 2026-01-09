<#
.LINK
    https://github.com/byronbayer/Powershell#remove-aadappregistrationswithpatternps1
#>

function Remove-AppRegistrationsWithPattern {
    param(
        #An array of App Registration patterns
        [Parameter(Mandatory = $true)]
        [string[]]
        $AppRegistrations,
        
        [Parameter(Mandatory = $true)]        
        [string]
        $TenantId,

        [Parameter(Mandatory = $true)]        
        [string]
        $AadUsername,
        
        [Parameter(Mandatory = $true)]
        [securestring]
        $AadPassword

    )

    function EnsureAzureAd() {
        if (!(Get-Module AzureAD)) {
            Write-Host "Installing/updating AzureAD module..."
            $temp = Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Scope CurrentUser
            $temp = Install-Module AzureAD -Scope CurrentUser -Force
        }
    
        Write-Host "Azure AD Authentication - Connecting to Azure AD..."
    
        if ($AadUsername -and $AadPassword) {
            Write-Host "Azure AD Authentication - Username and password set."
            $Credentials = New-Object -TypeName "System.Management.Automation.PSCredential" -ArgumentList $AadUsername, $AadPassword
        }
        else {
            Write-Host "Azure AD Authentication - Username and password not set"
            exit
        }
    
        $temp = Connect-AzureAD -TenantId $TenantId -Credential $Credentials
    }
    
    EnsureAzureAd
    $tenantDetail = Get-AzureADTenantDetail
    
    $defaultDomain = ($tenantDetail.VerifiedDomains | Where-Object Initial -EQ $true).Name
    $defaultDomain
    $AzureADApplications = Get-AzureADApplication | Where-Object -Property DisplayName -Like $AppRegistrations
    foreach ($AzureADApplication in $AzureADApplications) {
        $AzureADApplication.DisplayName
        Remove-AzureADApplication -ObjectId $AzureADApplication.ObjectId    
    }
     
}

$AppRegistrations = "", "", ""
$AadUsername = ""
$AadPassword = ConvertTo-SecureString '' -AsPlainText -Force
$TenantId = ""
Remove-AppRegistrationsWithPattern -AppRegistrations $AppRegistrations -AadUsername $AadUsername -AadPassword $AadPassword -TenantId $TenantId
