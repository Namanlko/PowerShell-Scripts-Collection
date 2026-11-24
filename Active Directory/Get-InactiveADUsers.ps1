#Requires -Modules ActiveDirectory
<#
.SYNOPSIS
    Lists enabled AD user accounts that have not logged on for N days.

.DESCRIPTION
    Wraps Search-ADAccount -AccountInactive and exports the result to CSV.
    Useful for periodic access reviews and clean-up of stale accounts.

    Note: LastLogonDate is based on the replicated lastLogonTimestamp attribute,
    which is only accurate to roughly 14 days. Do not use a threshold below ~30 days.

.PARAMETER DaysInactive
    Accounts with no logon in at least this many days are reported. Default 90.

.PARAMETER SearchBase
    Optional OU distinguished name to limit the search.

.PARAMETER IncludeDisabled
    Also include accounts that are already disabled.

.PARAMETER Server
    Optional domain controller / domain to query.

.PARAMETER OutputCsvPath
    CSV output path. Defaults to a timestamped file in the current folder.

.EXAMPLE
    .\Get-InactiveADUsers.ps1 -DaysInactive 120 -SearchBase "OU=Staff,DC=contoso,DC=com"
#>
[CmdletBinding()]
param(
    [ValidateRange(1, 3650)]
    [int]$DaysInactive = 90,

    [string]$SearchBase,

    [switch]$IncludeDisabled,

    [string]$Server,

    [string]$OutputCsvPath = ".\InactiveADUsers_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"
)

$searchParams = @{
    AccountInactive = $true
    UsersOnly       = $true
    TimeSpan        = [TimeSpan]::FromDays($DaysInactive)
    ErrorAction     = 'Stop'
}
if ($SearchBase) { $searchParams.SearchBase = $SearchBase }
if ($Server)     { $searchParams.Server     = $Server }

Write-Host "Searching for accounts inactive for $DaysInactive+ days..." -ForegroundColor Cyan

$accounts = Search-ADAccount @searchParams
if (-not $IncludeDisabled) { $accounts = $accounts | Where-Object Enabled }

$report = $accounts | ForEach-Object {
    $lastLogon = $_.LastLogonDate
    [PSCustomObject]@{
        SamAccountName    = $_.SamAccountName
        Name              = $_.Name
        Enabled           = $_.Enabled
        LastLogonDate     = $lastLogon
        DaysSinceLogon    = if ($lastLogon) { [int]((Get-Date) - $lastLogon).TotalDays } else { 'Never' }
        PasswordNeverExpires = $_.PasswordNeverExpires
        OU                = ($_.DistinguishedName -replace '^CN=.+?(?<!\\),', '')
    }
} | Sort-Object { if ($_.LastLogonDate) { $_.LastLogonDate } else { [datetime]::MinValue } }

$count = @($report).Count
if ($count -eq 0) {
    Write-Host 'No inactive accounts found.' -ForegroundColor Green
    return
}

$report | Export-Csv -Path $OutputCsvPath -NoTypeInformation -Encoding UTF8
Write-Host "$count inactive account(s) exported to: $OutputCsvPath" -ForegroundColor Cyan
