function New-AzServiceBus {
    param(
        [Parameter(Mandatory = $true)]
        [string]
        $ResourceGroup,
        [Parameter(Mandatory = $true)]
        [string]
        $Location,
        [Parameter(Mandatory = $true)]
        [string]
        $NamespaceName,
        [Parameter(Mandatory = $true)]
        [string]
        $QueueName,
        [Parameter(Mandatory = $true)]
        [string]
        $PolicyName
    )
    # Create a resource group 
    New-AzResourceGroup -Name $ResourceGroup -Location $Location
    # Create a Messaging namespace
    New-AzServiceBusNamespace -ResourceGroupName $ResourceGroup -Name $NamespaceName -Location $Location -Verbose
    # Create a queue 
    New-AzServiceBusQueue -ResourceGroupName $ResourceGroup -NamespaceName $NamespaceName -Name $QueueName -EnablePartitioning $False
    # Get primary connection string (required in next step)
    Get-AzServiceBusKey -ResourceGroupName $ResourceGroup -Namespace $NamespaceName -Name $PolicyName
}
function New-AzServiceBusSasToken {  
    param( 
           
        [Parameter(Mandatory = $true)]
        [string]
        $Namespace,
        [Parameter(Mandatory = $true)]
        [string]
        $PolicyName,
        [Parameter(Mandatory = $true)]
        [string]
        $Key
    )
    $origin = [DateTime]"1/1/1970 00:00" 
    $Expiry = (Get-Date).AddMinutes(5)    

    #compute the token expiration time.
    $diff = New-TimeSpan -Start $origin -End $Expiry 
    $tokenExpirationTime = [Convert]::ToInt32($diff.TotalSeconds)

    #create the string that will be hashed
    $stringToSign = [Web.HttpUtility]::UrlEncode($Namespace) + "`n" + $tokenExpirationTime

    #new-up the HMACSHA256 class
    $hmacsha = New-Object -TypeName System.Security.Cryptography.HMACSHA256
    $hmacsha.Key = [Text.Encoding]::UTF8.GetBytes($Key)

    #hash is computed with the HMACSHA256 class instance. The hash is converted to a base 64 string
    $hash = $hmacsha.ComputeHash([Text.Encoding]::UTF8.GetBytes($stringToSign))
    $signature = [Convert]::ToBase64String($hash)

    #create the token
    $token = [string]::Format([Globalization.CultureInfo]::InvariantCulture, `
            "SharedAccessSignature sr={0}&sig={1}&se={2}&skn={3}", `
            [Web.HttpUtility]::UrlEncode($Namespace), `
            [Web.HttpUtility]::UrlEncode($signature), `
            $tokenExpirationTime, $PolicyName) 
    return $token

}
function Send-AzServiceBusMessage {
    param(
        [Parameter(Mandatory = $true)]
        [string]
        $ResourceGroupName,
        [Parameter(Mandatory = $true)]
        [string]
        $NamespaceName,
        [Parameter(Mandatory = $true)]
        [string]
        $QueueName,    
        [Parameter(Mandatory = $false)]
        [string]
        $PolicyName = 'RootManageSharedAccessKey'
    )
      
    $message = [pscustomobject] @{ "Body" = "Test message"; }
    
    $Namespace = (Get-AzServiceBusNamespace -ResourceGroupName $ResourceGroupName -Name $namespacename).Name
    $key = (Get-AzServiceBusKey -ResourceGroupName $ResourceGroupName -Namespace $namespacename -Name $PolicyName).PrimaryKey
    $body = $Message.Body 
    $Message.psobject.properties.Remove("Body")

    #set up the parameters for the Invoke-WebRequest
    $uri = "https://$Namespace.servicebus.windows.net/$QueueName/messages"
    $token = New-AzServiceBusSasToken -Namespace $Namespace -Policy $PolicyName -Key $Key
    $headers = @{ "Authorization" = "$token"; "Content-Type" = "application/atom+xml;type=entry;charset=utf-8" } 
    $headers.Add("BrokerProperties", $(ConvertTo-Json -InputObject $Message -Compress))

    #Invoke-WebRequest call.
    #The normal output of the command is redirected to the $null automatic variable.
    #If an error occurs, Invoke-WebRequest will output the error to the error stream stderr.
    Invoke-WebRequest -Uri $uri -Headers $headers -Method Post -Body $body > $null
}

$ResourceGroup = 'test.rg.001'
$NameSpaceName = "testsbnamespace001"
$QueueName = "testqueue"
$PolicyName = "RootManageSharedAccessKey"
$Location = "UK South"

Install-Module Az.ServiceBus

# New-AzServiceBus -ResourceGroup $ResourceGroup `
#     -Location $Location `
#     -NamespaceName $NameSpaceName `
#     -QueueName $QueueName `
#     -PolicyName $PolicyName

 Send-AzServiceBusMessage -ResourceGroupName $ResourceGroup `
     -NamespaceName $NameSpaceName `
     -QueueName $QueueName `
     -PolicyName $PolicyName