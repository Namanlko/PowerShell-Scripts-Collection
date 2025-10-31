<#
.SYNOPSIS
Stops Windows Search service, deletes the Windows.edb file, and restarts the service.

.DESCRIPTION
This script disables and stops the Windows Search service, deletes the .edb file (Windows Search database), 
and attempts to start the service again. It retries starting the service if the first attempt fails 
and sets its startup type to Automatic.

.PARAMETER EdbFilePath
Path to the Windows Search .edb file. Defaults to the standard location.

.PARAMETER ServiceName
Name of the Windows Search service. Default is 'WSearch'.

.EXAMPLE
.\Clear-WindowsSearchEdb.ps1
#>

param (
    [string]$EdbFilePath = "C:\ProgramData\Microsoft\Search\Data\Applications\Windows\Windows.edb",
    [string]$ServiceName = "WSearch"
)

function Stop-WindowsSearchService {
    try {
        Write-Host "`n[INFO] Stopping Windows Search service..."
        Stop-Service -Name $ServiceName -Force -ErrorAction Stop
        Set-Service -Name $ServiceName -StartupType Disabled
        Write-Host "[OK] Service stopped and disabled."
    }
    catch {
        Write-Host "[ERROR] Failed to stop the service: $_"
        exit 1
    }
}

function Start-WindowsSearchService {
    Write-Host "`n[INFO] Setting service to 'Automatic'..."
    try {
        Set-Service -Name $ServiceName -StartupType Automatic
    }
    catch {
        Write-Host "[ERROR] Failed to set startup type: $_"
        exit 1
    }

    # Try starting the service (up to 2 attempts)
    for ($i = 1; $i -le 2; $i++) {
        try {
            Write-Host "[INFO] Attempt ${i}: Starting Windows Search service..."
            Start-Service -Name $ServiceName -ErrorAction Stop
            Write-Host "[OK] Service started successfully."
            return
        }
        catch {
            Write-Host "[WARNING] Attempt ${i} failed to start service: $_"
            Start-Sleep -Seconds 3
        }
    }

    Write-Host "[ERROR] Failed to start Windows Search service after 2 attempts."
}

function Delete-EdbFile {
    try {
        Write-Host "`n[INFO] Checking for .edb file at: $EdbFilePath"
        if (Test-Path $EdbFilePath) {
            Remove-Item -Path $EdbFilePath -Force
            Write-Host "[OK] .edb file deleted successfully."
        }
        else {
            Write-Host "[INFO] No .edb file found at the specified location."
        }
    }
    catch {
        Write-Host "[ERROR] Failed to delete the .edb file: $_"
        exit 1
    }
}

# MAIN EXECUTION
Write-Host "`n======== Windows Search EDB Cleanup Script ========"

Stop-WindowsSearchService
Delete-EdbFile
Start-WindowsSearchService

Write-Host "`n[COMPLETED] Search database cleanup complete."
