#Requires -Modules VMware.PowerCLI
<#
.SYNOPSIS
    Summarises ESXi host health: state, version, CPU/memory load, uptime, VM count.

.PARAMETER VCenterServer
    vCenter Server FQDN or IP.

.PARAMETER OutputCsvPath
    CSV output path. Defaults to a timestamped file in the current folder.

.PARAMETER Credential
    Optional vCenter credentials.

.EXAMPLE
    .\Get-ESXiHostReport.ps1 -VCenterServer vcenter.contoso.com
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$VCenterServer,

    [string]$OutputCsvPath = ".\ESXiHosts_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv",

    [System.Management.Automation.PSCredential]$Credential
)

$weConnected = $false
try {
    if (-not ($global:DefaultVIServers | Where-Object { $_.Name -eq $VCenterServer -and $_.IsConnected })) {
        $connect = @{ Server = $VCenterServer; ErrorAction = 'Stop' }
        if ($Credential) { $connect.Credential = $Credential }
        $null = Connect-VIServer @connect
        $weConnected = $true
    }

    $vmCounts = @{}
    Get-VM -Server $VCenterServer | Group-Object { $_.VMHost.Name } | ForEach-Object { $vmCounts[$_.Name] = $_.Count }

    $report = foreach ($h in Get-VMHost -Server $VCenterServer) {
        $boot   = $h.ExtensionData.Runtime.BootTime
        $cpuPct = if ($h.CpuTotalMhz)   { [math]::Round(($h.CpuUsageMhz / $h.CpuTotalMhz) * 100, 1) } else { $null }
        $memPct = if ($h.MemoryTotalGB) { [math]::Round(($h.MemoryUsageGB / $h.MemoryTotalGB) * 100, 1) } else { $null }

        [PSCustomObject]@{
            Host            = $h.Name
            Cluster         = if ($h.Parent -and $h.Parent.GetType().Name -match 'Cluster') { $h.Parent.Name } else { '' }
            ConnectionState = $h.ConnectionState
            PowerState      = $h.PowerState
            Version         = $h.Version
            Build           = $h.Build
            Model           = "$($h.Manufacturer) $($h.Model)"
            CpuUsagePct     = $cpuPct
            MemUsagePct     = $memPct
            MemoryTotalGB   = [math]::Round($h.MemoryTotalGB, 0)
            VMCount         = [int]$vmCounts[$h.Name]
            UptimeDays      = if ($boot) { [int]((Get-Date) - $boot.ToLocalTime()).TotalDays } else { $null }
            OverallStatus   = $h.ExtensionData.OverallStatus
        }
    }

    $report = @($report | Sort-Object Cluster, Host)
    $report | Export-Csv -Path $OutputCsvPath -NoTypeInformation -Encoding UTF8
    $report | Format-Table Host, Cluster, ConnectionState, CpuUsagePct, MemUsagePct, VMCount, UptimeDays, OverallStatus -AutoSize
    Write-Host "Report saved to: $OutputCsvPath" -ForegroundColor Cyan
}
finally {
    if ($weConnected) { Disconnect-VIServer -Server $VCenterServer -Confirm:$false -ErrorAction SilentlyContinue | Out-Null }
}
