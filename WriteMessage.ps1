function Write-Message {
    param(    
        [Parameter (Mandatory = $true)]
        [string]
        $message,    
        [system.diagnostics.stopwatch]
        $stopwatch
    )
    $ESC = [char]27
    $foregroundblack = "$ESC[30m"    
    $backgroundWhite = "$ESC[47m"
    $foregroundWhite = "$ESC[37m"    
    $backgroundBlue = "$ESC[44m"

    if ($stopwatch) {
        $time = $stopwatch.Elapsed.ToString('hh\:mm\:ss')
        Write-Output "$foregroundblack $backgroundWhite $time $backgroundBlue $foregroundWhite - $message"    
    }
    else {
        Write-Output "$backgroundBlue $foregroundWhite $message"    
    }    
}

$stopwatch = [system.diagnostics.stopwatch]::StartNew()
Write-Message -stopwatch $stopwatch -message 'Testing the message'
'Doing other stuff'
Start-Sleep -Seconds 5
'Doing more stuff'
Write-Message -stopwatch $stopwatch -message 'Bit later on'
Write-Message -message "Some other stuff"