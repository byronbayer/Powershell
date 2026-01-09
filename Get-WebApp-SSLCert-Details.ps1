<#
.LINK
    https://github.com/byronbayer/Powershell#get-webapp-sslcert-detailsps1
#>

# Retrieve Azure Web App and Azure Certificate Details.
# Helps to find out which Web Apps are enabled for TLS 1.0 or 1.1 so they can be moved to 1.2
# Helps to find out few other info like if HttpsOnly is enabled, Tags, Cert Thumbprint and Expiry date
# Generates CSV files

Clear-Host
# Pick all subscriptions except Azure AD
$AllSubscription = Get-AzSubscription | Where-Object { $_.name -inotlike "*Azure Active Directory" }
$outputFolder = 'C:\Scripts'

# Few empty arrays
$AllSSLCerts = @()
$AllWebApps = @()


foreach ($Subscription in $AllSubscription) {

    write-host $Subscription.Name
    $null = Select-AzSubscription -SubscriptionId $Subscription.ID

    Write-Host 'Getting the Certs'
    # Web App SSL Certificates
    $WebAppCerts = Get-AzWebAppCertificate 
    $AllWebAppCerts = $WebAppCerts | Select-Object @{n = "SubscriptionName"; e = { $Subscription.Name } }, FriendlyName, IssueDate, ExpirationDate, `
        Thumbprint, SubjectName, Location, Issuer, @{n = "ResourceType"; e = { $_.Type } }
       
    # Get Azure Web Apps
    Write-Host 'Getting the WebApps'
    $WebApps = Get-AzWebApp

    Write-Host 'Getting the WebApp details'
    
    # Select Specific Attributes from web apps
    $WebAppsDetails = $WebApps | Select-Object @{n = "SubscriptionName"; e = { $Subscription.Name } }, Name, State, Enabled, ResourceGroup, Location, DefaultHostName, Tag-*, httpsOnly, `
    @{n = "minTLSVersion"; e = { (Get-AzResource -ResourceGroupName $_.ResourceGroup  -ResourceType Microsoft.Web/sites/config -ResourceName $_.name -ApiVersion 2016-08-01).Properties.minTLSVersion } }, `
    @{n = "CertName"; e = { (Get-AzWebAppSSLBinding -WebAppName $_.Name -ResourceGroupName $_.ResourceGroup).Name } }, `
    @{n = "Thumbprint"; e = { (Get-AzWebAppSSLBinding -WebAppName $_.Name -ResourceGroupName $_.ResourceGroup).Thumbprint } }, SubjectName, ExpirationDate, Issuer
    
    Write-Host 'Combining cert details and WebApp details '

    #find out ExpiryDate, SubjectNames, Issuer Name
    foreach ($WebApp in $WebAppsDetails) {
        if ($WebApp.Thumbprint) {
            $Cert = $AllWebAppCerts | Where-Object { $_.Thumbprint -eq $WebApp.Thumbprint }
            $WebApp.ExpirationDate = $cert.ExpirationDate
            $WebApp.SubjectName = $cert.SubjectName
            $WebApp.Issuer = $cert.Issuer
        }
    }

    $AllSSLCerts += $AllWebAppCerts | Sort-Object expirationdate
    $AllWebApps += $WebAppsDetails
    Remove-Variable -Name AllWebAppCerts
    Remove-Variable -Name WebAppsDetails
    Remove-Variable -Name WebAppCerts
    Remove-Variable -Name WebApps
}
$AllSSLCerts | Export-Clixml $outputFolder\AllSSLCerts.xml
$AllWebApps | Export-Clixml $outputFolder\AllWebApps.xml

$AllSSLCerts | Export-Csv $outputFolder\AllSSLCerts.csv -NoTypeInformation
$AllWebApps | Export-Csv $outputFolder\AllWebApps.csv -NoTypeInformation

$AllSSLCerts | ConvertTo-Json | Out-File $outputFolder\AllSSLCerts.json
$AllWebApps | ConvertTo-Json | Out-File $outputFolder\AllWebApps.json
