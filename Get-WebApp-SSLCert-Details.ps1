# Retrieve Azure Web App and Azure Certificate Details.
# Helps to find out which Web Apps are enabled for TLS 1.0 or 1.1 so they can be moved to 1.2
# Helps to find out few other info like if HttpsOnly is enabled, Tags, Cert Thumbprint and Expiry date
# Generates CSV files

Clear-Host
# Pick all subscriptions except Azure AD
$AllSubscription = Get-AzSubscription -SubscriptionId | Where-Object { $_.name -inotlike "*Azure Active Directory" }

# Few empty arrays
$AllSSLCerts = @()
$AllWebApps = @()


foreach ($Subscription in $AllSubscription) {
    $Subscription.Name
    $null = Select-AzSubscription -SubscriptionId $Subscription.ID

    # Web App SSL Certificates
    $WebAppCerts = Get-AzWebAppCertificate 
    $AllWebAppCerts = $WebAppCerts | Select-Object @{n = "SubscriptionName"; e = { $Subscription.Name } }, FriendlyName, IssueDate, ExpirationDate, `
        Thumbprint, SubjectName, Location, Issuer, @{n = "ResourceType"; e = { $_.Type } }
       
    # Get Azure Web Apps
    $WebApps = Get-AzWebApp 

    # Select Specific Attributes from web apps
    $WebAppsDetails = $WebApps | Select-Object @{n = "SubscriptionName"; e = { $Subscription.Name } }, Name, State, Enabled, ResourceGroup, Location, DefaultHostName, Tag-*, httpsOnly, `
    @{n = "minTLSVersion"; e = { (Get-AzResource -ResourceGroupName $_.ResourceGroup  -ResourceType Microsoft.Web/sites/config -ResourceName $_.name -ApiVersion 2016-08-01).Properties.minTLSVersion } }, `
    @{n = "CertName"; e = { (Get-AzWebAppSSLBinding -WebAppName $_.Name -ResourceGroupName $_.ResourceGroup).Name } }, `
    @{n = "Thumbprint"; e = { (Get-AzWebAppSSLBinding -WebAppName $_.Name -ResourceGroupName $_.ResourceGroup).Thumbprint } }, SubjectName, ExpirationDate, Issuer
    
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
$AllSSLCerts | Export-Clixml C:\Scripts\AllSSLCerts2.xml
$AllWebApps | Export-Clixml C:\Scripts\AllWebApps2.xml

$AllSSLCerts | Export-Csv C:\Scripts\AllSSLCerts2.csv -NoTypeInformation
$AllWebApps | Export-Csv C:\Scripts\AllWebApps2.csv -NoTypeInformation

$AllSSLCerts | Export- C:\Scripts\AllSSLCerts2.csv -NoTypeInformation
$AllWebApps | Export-Csv C:\Scripts\AllWebApps2.csv -NoTypeInformation
