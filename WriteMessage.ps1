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

write-message "Starting script..." $stopwatch