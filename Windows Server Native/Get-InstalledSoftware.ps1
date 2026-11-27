<#
.SYNOPSIS
    Lists installed software on one or more servers (machine-wide installs).

.DESCRIPTION
    Reads the 64-bit and 32-bit Uninstall registry keys. This is fast and has no
    side effects - unlike Win32_Product, which triggers an MSI consistency check
    (and possible repairs) on every installed package and should be avoided.

.PARAMETER ComputerName
    Target servers. Default: local computer.

.PARAMETER Name
    Optional wildcard filter on the display name, e.g. '*SQL*'.

.PARAMETER Credential
    Optional alternate credentials for remote servers.

.PARAMETER OutputCsvPath
    Optional CSV output path.

.EXAMPLE
    .\Get-InstalledSoftware.ps1 -ComputerName srv01,srv02 -Name '*Java*' -OutputCsvPath .\java.csv
#>
[CmdletBinding()]
param(
    [string[]]$ComputerName = $env:COMPUTERNAME,

    [string]$Name = '*',

    [System.Management.Automation.PSCredential]$Credential,

    [string]$OutputCsvPath
)

$collector = {
    $paths = @(
        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
        'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'
    )
    foreach ($p in $paths) {
        Get-ItemProperty -Path $p -ErrorAction SilentlyContinue |
            Where-Object { $_.DisplayName -and -not $_.SystemComponent } |
            ForEach-Object {
                [PSCustomObject]@{
                    DisplayName     = $_.DisplayName
                    DisplayVersion  = $_.DisplayVersion
                    Publisher       = $_.Publisher
                    InstallDate     = $_.InstallDate
                    Architecture    = if ($p -like '*WOW6432Node*') { 'x86' } else { 'x64/native' }
                    UninstallString = $_.UninstallString
                }
            }
    }
}

$results = foreach ($server in ($ComputerName | Where-Object { $_ } | Select-Object -Unique)) {
    try {
        if ($server -in @('.', 'localhost', $env:COMPUTERNAME)) {
            $rows = & $collector
        }
        else {
            $ic = @{ ComputerName = $server; ScriptBlock = $collector; ErrorAction = 'Stop' }
            if ($Credential) { $ic.Credential = $Credential }
            $rows = Invoke-Command @ic
        }
        $rows | Where-Object { $_.DisplayName -like $Name } | ForEach-Object {
            [PSCustomObject]@{
                ComputerName    = $server
                DisplayName     = $_.DisplayName
                DisplayVersion  = $_.DisplayVersion
                Publisher       = $_.Publisher
                InstallDate     = $_.InstallDate
                Architecture    = $_.Architecture
                UninstallString = $_.UninstallString
            }
        }
    }
    catch {
        Write-Warning "${server}: $($_.Exception.Message)"
    }
}

$results = @($results | Sort-Object ComputerName, DisplayName)
if ($results.Count -eq 0) { Write-Host 'No matching software found.' -ForegroundColor Yellow; return }

if ($OutputCsvPath) {
    $results | Export-Csv -Path $OutputCsvPath -NoTypeInformation -Encoding UTF8
    Write-Host "$($results.Count) entries saved to: $OutputCsvPath" -ForegroundColor Cyan
}
else {
    $results | Format-Table ComputerName, DisplayName, DisplayVersion, Publisher -AutoSize
}
