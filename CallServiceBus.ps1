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

    #Create a new instance of the HMACSHA256 class and set the key to UTF8 for the size of $Key
    $hmacsha = New-Object -TypeName System.Security.Cryptography.HMACSHA256
    $hmacsha.Key = [Text.Encoding]::UTF8.GetBytes($Key)

    #create the string that will be used when cumputing the hash
    $stringToSign = [Web.HttpUtility]::UrlEncode($Namespace) + "`n" + $tokenExpirationTime

    #Compute hash from the HMACSHA256 instance we created above using the size of the UTF8 string above.
    $hash = $hmacsha.ComputeHash([Text.Encoding]::UTF8.GetBytes($stringToSign))
    #Convert the hash to base 64 string
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
      
    $message = [PSCustomObject] @{ "Body" = "Test message"; }
    
    $Namespace = (Get-AzServiceBusNamespace -ResourceGroupName $ResourceGroupName -Name $namespacename).Name
    $key = (Get-AzServiceBusKey -ResourceGroupName $ResourceGroupName -Namespace $namespacename -Name $PolicyName).PrimaryKey
    
    $body = $Message.Body 
    $Message.psobject.properties.Remove("Body")

    $token = New-AzServiceBusSasToken -Namespace $Namespace -Policy $PolicyName -Key $Key
    
    #set up the parameters for the Invoke-WebRequest
    $headers = @{ "Authorization" = "$token"; "Content-Type" = "application/atom+xml;type=entry;charset=utf-8" }
    $uri = "https://$Namespace.servicebus.windows.net/$QueueName/messages"
    $headers.Add("BrokerProperties", $(ConvertTo-Json -InputObject $Message -Compress))

    #Invoke-WebRequest call.
    #The normal output of the command is redirected to the $null automatic variable.
    #If an error occurs, Invoke-WebRequest will output the error to the error stream stderr.
    Invoke-WebRequest -Uri $uri -Headers $headers -Method Post -Body $body > $null
}

Login-AzAccount
$ResourceGroup = 'MyResourceGroup'
$NameSpaceName = "MyNameSpaceUnique001"
$QueueName = "MyQueue"
$PolicyName = "RootManageSharedAccessKey"
$Location = "UK South"

$serviceBussInstalled = Get-InstalledModule Az.ServiceBus
if (!$serviceBussInstalled) {
    Install-Module Az.ServiceBus
}

New-AzServiceBus -ResourceGroup $ResourceGroup `
    -Location $Location `
    -NamespaceName $NameSpaceName `
    -QueueName $QueueName `
    -PolicyName $PolicyName

Send-AzServiceBusMessage -ResourceGroupName $ResourceGroup `
    -NamespaceName $NameSpaceName `
    -QueueName $QueueName `
    -PolicyName $PolicyName