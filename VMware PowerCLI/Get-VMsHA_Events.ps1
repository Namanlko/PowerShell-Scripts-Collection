<#
.SYNOPSIS
    Retrieves VMware HA restart events from the last 24 hours 
    and exports the details to a CSV file.

.DESCRIPTION
    This script uses VMware PowerCLI to connect to a vCenter Server,
    collect recent VM restart events triggered by VMware High Availability (HA),
    and export the event details (VM name, IP address, timestamp, and message)
    to a CSV report for review or troubleshooting.

.PARAMETER DaysBack
    The number of days to look back when searching for events (default: 1).

.PARAMETER ExportPath
    The file path where the CSV report will be saved.

.NOTES
    Author  : PowerCLI Community Script
    Version : 1.1
    Date    : 2025-10-27
#>

# ============================
# Step 1: Load VMware PowerCLI
# ============================
Import-Module VMware.PowerCLI -ErrorAction Stop

# ============================
# Step 2: Connect to vCenter
# ============================
Connect-VIServer -Server "vcenter.example.com"

# ============================
# Step 3: Define Script Parameters
# ============================
# Days to look back for HA restart events
$DaysBack = 1

# Define export directory (user can modify this)
$ExportDirectory = "C:\Reports"  # <-- Change this path as needed

# Create export directory if it doesn’t exist
if (-not (Test-Path $ExportDirectory)) {
    New-Item -ItemType Directory -Path $ExportDirectory | Out-Null
}

# Define export filename with timestamp for uniqueness
$Timestamp = (Get-Date).ToString("yyyyMMdd_HHmmss")
$ExportFileName = "VM_HA_Restart_Events_$Timestamp.csv"

# Combine directory and filename into full path
$ExportPath = Join-Path -Path $ExportDirectory -ChildPath $ExportFileName

# ============================
# Step 4: Retrieve and Filter Events
# ============================
Write-Host "Retrieving VMware HA restart events..." -ForegroundColor Cyan

$HAEvents = Get-VIEvent -MaxSamples 100000 `
                        -Start (Get-Date).AddDays(-$DaysBack) `
                        -Type Warning |
    Where-Object { $_.FullFormattedMessage -match "HA restarted" } |
    Select-Object `
        @{Name = "VM Name"; Expression = { $_.ObjectName }},
        @{Name = "IP Address"; Expression = { 
            try { (Get-View -Id $_.Vm.Vm).Guest.IpAddress } 
            catch { "N/A" } 
        }},
        @{Name = "Event Time"; Expression = { $_.CreatedTime }},
        @{Name = "Event Message"; Expression = { $_.FullFormattedMessage }} |
    Sort-Object "Event Time" -Descending

# ============================
# Step 5: Export Results to CSV
# ============================
if ($HAEvents) {
    $HAEvents | Export-Csv -Path $ExportPath -NoTypeInformation
    Write-Host "✅ HA Restart Events exported successfully to:" -ForegroundColor Green
    Write-Host "   $ExportPath" -ForegroundColor Cyan
} else {
    Write-Host "ℹ️ No HA restart events found in the last $DaysBack day(s)." -ForegroundColor Yellow
}

# ============================
# Step 6: Disconnect Session
# ============================
Disconnect-VIServer -Confirm:$false | Out-Null
Write-Host "Disconnected from vCenter." -ForegroundColor Gray
