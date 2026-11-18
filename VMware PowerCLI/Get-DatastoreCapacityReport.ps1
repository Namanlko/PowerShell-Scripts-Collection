#Requires -Modules VMware.PowerCLI
<#
.SYNOPSIS
    Reports datastore capacity and flags those running low on free space.

.PARAMETER VCenterServer
    vCenter Server FQDN or IP.

.PARAMETER WarnFreePercent
    Mark a datastore "Warning" at or below this free %. Default 20.

.PARAMETER CriticalFreePercent
    Mark a datastore "Critical" at or below this free %. Default 10.

.PARAMETER OutputCsvPath
    CSV output path. Defaults to a timestamped file in the current folder.

.PARAMETER Credential
    Optional vCenter credentials.

.EXAMPLE
    .\Get-DatastoreCapacityReport.ps1 -VCenterServer vcenter.contoso.com
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$VCenterServer,

    [ValidateRange(1, 99)]
    [int]$WarnFreePercent = 20,

    [ValidateRange(1, 99)]
    [int]$CriticalFreePercent = 10,

    [string]$OutputCsvPath = ".\DatastoreCapacity_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv",

    [System.Management.Automation.PSCredential]$Credential
)

if ($CriticalFreePercent -ge $WarnFreePercent) {
    Write-Error 'CriticalFreePercent must be lower than WarnFreePercent.'
    return
}

$weConnected = $false
try {
    if (-not ($global:DefaultVIServers | Where-Object { $_.Name -eq $VCenterServer -and $_.IsConnected })) {
        $connect = @{ Server = $VCenterServer; ErrorAction = 'Stop' }
        if ($Credential) { $connect.Credential = $Credential }
        $null = Connect-VIServer @connect
        $weConnected = $true
    }

    $report = Get-Datastore -Server $VCenterServer | ForEach-Object {
        $freePct = if ($_.CapacityGB -gt 0) { [math]::Round(($_.FreeSpaceGB / $_.CapacityGB) * 100, 1) } else { 0 }
        [PSCustomObject]@{
            Datastore   = $_.Name
            Type        = $_.Type
            State       = $_.State
            CapacityGB  = [math]::Round($_.CapacityGB, 1)
            FreeGB      = [math]::Round($_.FreeSpaceGB, 1)
            UsedGB      = [math]::Round($_.CapacityGB - $_.FreeSpaceGB, 1)
            FreePercent = $freePct
            Health      = if ($freePct -le $CriticalFreePercent) { 'Critical' }
                          elseif ($freePct -le $WarnFreePercent) { 'Warning' }
                          else { 'OK' }
        }
    } | Sort-Object FreePercent

    $report | Export-Csv -Path $OutputCsvPath -NoTypeInformation -Encoding UTF8
    $report | Format-Table -AutoSize

    $bad = @($report | Where-Object Health -ne 'OK').Count
    $color = if ($bad) { 'Yellow' } else { 'Green' }
    Write-Host "$bad datastore(s) at Warning/Critical. Report: $OutputCsvPath" -ForegroundColor $color
}
finally {
    if ($weConnected) { Disconnect-VIServer -Server $VCenterServer -Confirm:$false -ErrorAction SilentlyContinue | Out-Null }
}
