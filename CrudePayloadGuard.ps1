# CrudePayloadGuard.ps1 by Gorstak

function Register-SystemLogonScript {
    param (
        [string]$TaskName = "RunCrudePayloadGuardAtLogon"
    )

    # Define paths
    $scriptSource = $MyInvocation.MyCommand.Path
    if (-not $scriptSource) {
        # Fallback to determine script path
        $scriptSource = $PSCommandPath
        if (-not $scriptSource) {
            Write-Output "Error: Could not determine script path."
            return
        }
    }

    $targetFolder = "C:\Windows\Setup\Scripts\Bin"
    $targetPath = Join-Path $targetFolder (Split-Path $scriptSource -Leaf)

    # Create required folders
    if (-not (Test-Path $targetFolder)) {
        New-Item -Path $targetFolder -ItemType Directory -Force | Out-Null
        Write-Output "Created folder: $targetFolder"
    }

    # Copy the script
    try {
        Copy-Item -Path $scriptSource -Destination $targetPath -Force -ErrorAction Stop
        Write-Output "Copied script to: $targetPath"
    } catch {
        Write-Output "Failed to copy script: $_"
        return
    }

    # Define the scheduled task action and trigger
    $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -File `"$targetPath`""
    $trigger = New-ScheduledTaskTrigger -AtLogOn
    $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest

    # Register the task
    try {
        Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction SilentlyContinue
        Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger $trigger -Principal $principal
        Write-Output "Scheduled task '$TaskName' created to run at user logon under SYSTEM."
    } catch {
        Write-Output "Failed to register task: $_"
    }
}

# Run the functionMore actions
Register-SystemLogonScript

$job = Start-Job -ScriptBlock {
    $pattern = '(?i)(<script|javascript:|onerror=|onload=|alert\()'

    function Disable-Network-Briefly {
        $adapters = Get-NetAdapter | Where-Object { $_.Status -eq "Up" }
        foreach ($adapter in $adapters) {
            Disable-NetAdapter -Name $adapter.Name -Confirm:$false -ErrorAction SilentlyContinue
        }
        Start-Sleep -Seconds 3
        foreach ($adapter in $adapters) {
            Enable-NetAdapter -Name $adapter.Name -Confirm:$false -ErrorAction SilentlyContinue
        }
        Write-Host "🌐 Network briefly disabled"
    }

    function Add-XSSFirewallRule {
        param ([string]$url)
        try {
            $uri = [System.Uri]::new($url)
            $domain = $uri.Host
            $ruleName = "Block_XSS_$domain"

            if (-not (Get-NetFirewallRule -DisplayName $ruleName -ErrorAction SilentlyContinue)) {
                New-NetFirewallRule -DisplayName $ruleName `
                    -Direction Outbound `
                    -Action Block `
                    -RemoteAddress $domain `
                    -Protocol TCP `
                    -Profile Any `
                    -Description "Blocked due to potential XSS in URL"
                Write-Host "🚫 Domain blocked via firewall: $domain"
            }
        } catch {
            Write-Warning "⚠️ Could not block: $url"
        }
    }

    Register-WmiEvent -Query "SELECT * FROM __InstanceCreationEvent WITHIN 2 WHERE TargetInstance ISA 'Win32_Process'" -Action {
        $proc = $Event.SourceEventArgs.NewEvent.TargetInstance
        $cmdline = $proc.CommandLine

        if ($cmdline -match $pattern) {
            Write-Host "`n❌ Potential XSS detected in: $cmdline"

            if ($cmdline -match 'https?://[^\s"]+') {
                $url = $matches[0]
                Disable-Network-Briefly
                Add-XSSFirewallRule -url $url
            }
        }
    } | Out-Null

    while ($true) { Start-Sleep -Seconds 5 }
}
