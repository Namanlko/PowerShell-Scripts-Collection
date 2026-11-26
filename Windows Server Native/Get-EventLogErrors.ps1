<#
.SYNOPSIS
    Summarises recent Error/Critical events from Windows event logs.

.DESCRIPTION
    Pulls Critical and Error events from the chosen logs for the last N hours using
    Get-WinEvent -FilterHashtable (server-side filtering, so it is fast), groups
    them by source and event ID, and optionally exports the full detail.

.PARAMETER ComputerName
    Target computer. Default: local computer.

.PARAMETER LogName
    Logs to search. Default System and Application.

.PARAMETER Hours
    Look-back window in hours. Default 24.

.PARAMETER IncludeWarnings
    Also include Warning-level events.

.PARAMETER Credential
    Optional alternate credentials.

.PARAMETER OutputCsvPath
    Optional CSV path for the full event detail.

.EXAMPLE
    .\Get-EventLogErrors.ps1 -ComputerName sql01 -Hours 48 -OutputCsvPath .\sql01_errors.csv
#>
[CmdletBinding()]
param(
    [string]$ComputerName = $env:COMPUTERNAME,

    [string[]]$LogName = @('System', 'Application'),

    [ValidateRange(1, 8760)]
    [int]$Hours = 24,

    [switch]$IncludeWarnings,

    [System.Management.Automation.PSCredential]$Credential,

    [string]$OutputCsvPath
)

$levels = if ($IncludeWarnings) { 1, 2, 3 } else { 1, 2 }
$start  = (Get-Date).AddHours(-$Hours)

$events = foreach ($log in $LogName) {
    $params = @{
        FilterHashtable = @{ LogName = $log; Level = $levels; StartTime = $start }
        ErrorAction     = 'Stop'
    }
    if ($ComputerName -notin @('.', 'localhost', $env:COMPUTERNAME)) {
        $params.ComputerName = $ComputerName
        if ($Credential) { $params.Credential = $Credential }
    }

    try { Get-WinEvent @params }
    catch {
        # "No events were found" is reported as an error by Get-WinEvent; treat it as an empty result.
        if ($_.FullyQualifiedErrorId -notlike 'NoMatchingEventsFound*') {
            Write-Warning "${log}: $($_.Exception.Message)"
        }
    }
}

$events = @($events)
if ($events.Count -eq 0) {
    Write-Host "No matching events on $ComputerName in the last $Hours hour(s)." -ForegroundColor Green
    return
}

Write-Host "`n$($events.Count) event(s) on $ComputerName in the last $Hours hour(s). Top sources:" -ForegroundColor Cyan
$events |
    Group-Object LogName, ProviderName, Id |
    Sort-Object Count -Descending |
    Select-Object -First 15 @{ N = 'Count'; E = { $_.Count } },
                            @{ N = 'Log';   E = { $_.Group[0].LogName } },
                            @{ N = 'Source'; E = { $_.Group[0].ProviderName } },
                            @{ N = 'EventId'; E = { $_.Group[0].Id } },
                            @{ N = 'Level'; E = { $_.Group[0].LevelDisplayName } },
                            @{ N = 'LastSeen'; E = { ($_.Group | Sort-Object TimeCreated -Descending | Select-Object -First 1).TimeCreated } } |
    Format-Table -AutoSize

if ($OutputCsvPath) {
    $events | Select-Object TimeCreated, LogName, LevelDisplayName, ProviderName, Id, MachineName,
        @{ N = 'Message'; E = { ($_.Message -replace '\s+', ' ').Trim() } } |
        Export-Csv -Path $OutputCsvPath -NoTypeInformation -Encoding UTF8
    Write-Host "Full detail saved to: $OutputCsvPath" -ForegroundColor Cyan
}
