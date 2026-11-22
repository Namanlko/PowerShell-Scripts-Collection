<#
.SYNOPSIS
    Reports free space on fixed disks across one or more servers.

.DESCRIPTION
    Queries Win32_LogicalDisk (fixed disks only) via CIM and flags volumes at or
    below a free-space threshold. Servers that cannot be queried are listed as
    "Unreachable" instead of aborting the run.

.PARAMETER ComputerName
    Server names. Default: local computer.

.PARAMETER ListPath
    Optional text file of server names (one per line, # comments allowed).

.PARAMETER ThresholdPercent
    Flag volumes with free space at or below this %. Default 15.

.PARAMETER OnlyBelowThreshold
    Only output volumes that are below the threshold.

.PARAMETER Credential
    Optional alternate credentials.

.PARAMETER OutputCsvPath
    Optional CSV output path.

.EXAMPLE
    .\Get-DiskSpaceReport.ps1 -ListPath .\servers.txt -ThresholdPercent 20 -OnlyBelowThreshold
#>
[CmdletBinding()]
param(
    [string[]]$ComputerName = $env:COMPUTERNAME,

    [string]$ListPath,

    [ValidateRange(1, 99)]
    [int]$ThresholdPercent = 15,

    [switch]$OnlyBelowThreshold,

    [System.Management.Automation.PSCredential]$Credential,

    [string]$OutputCsvPath
)

$targets = [System.Collections.Generic.List[string]]::new()
$ComputerName | Where-Object { $_ } | ForEach-Object { $targets.Add($_.Trim()) }

if ($ListPath) {
    if (-not (Test-Path -LiteralPath $ListPath -PathType Leaf)) { Write-Error "List file not found: $ListPath"; return }
    Get-Content -LiteralPath $ListPath | ForEach-Object { $_.Trim() } |
        Where-Object { $_ -and -not $_.StartsWith('#') } | ForEach-Object { $targets.Add($_) }
}

$report = foreach ($server in ($targets | Select-Object -Unique)) {
    $session = $null
    try {
        $cim = @{ ClassName = 'Win32_LogicalDisk'; Filter = 'DriveType=3'; ErrorAction = 'Stop' }
        if ($server -notin @('.', 'localhost', $env:COMPUTERNAME)) {
            $sp = @{ ComputerName = $server; ErrorAction = 'Stop' }
            if ($Credential) { $sp.Credential = $Credential }
            $session = New-CimSession @sp
            $cim.CimSession = $session
        }

        foreach ($d in (Get-CimInstance @cim | Where-Object Size)) {
            $freePct = [math]::Round(($d.FreeSpace / $d.Size) * 100, 1)
            [PSCustomObject]@{
                ComputerName = $server
                Drive        = $d.DeviceID
                Label        = $d.VolumeName
                SizeGB       = [math]::Round($d.Size / 1GB, 1)
                FreeGB       = [math]::Round($d.FreeSpace / 1GB, 1)
                FreePercent  = $freePct
                Status       = if ($freePct -le $ThresholdPercent) { 'LOW' } else { 'OK' }
            }
        }
    }
    catch {
        [PSCustomObject]@{
            ComputerName = $server; Drive = $null; Label = $null; SizeGB = $null; FreeGB = $null
            FreePercent  = $null;   Status = "Unreachable: $($_.Exception.Message)"
        }
    }
    finally {
        if ($session) { Remove-CimSession $session -ErrorAction SilentlyContinue }
    }
}

if ($OnlyBelowThreshold) { $report = $report | Where-Object { $_.Status -ne 'OK' } }
$report = @($report | Sort-Object FreePercent)

if ($report.Count -eq 0) {
    Write-Host 'Nothing to report - all volumes are above the threshold.' -ForegroundColor Green
    return
}

$report | Format-Table -AutoSize
if ($OutputCsvPath) {
    $report | Export-Csv -Path $OutputCsvPath -NoTypeInformation -Encoding UTF8
    Write-Host "Report saved to: $OutputCsvPath" -ForegroundColor Cyan
}
