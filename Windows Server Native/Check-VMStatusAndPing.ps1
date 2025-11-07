#--------------------------------------------------------------
# Script to check the ping status of VMs and output results to a CSV file
#--------------------------------------------------------------

# Define the path to the input file (list of VM names) and the output CSV file
$vmListFile = "vm_list.txt"  # Change this path as needed
$outputCsvFile = "vm_ping_status.csv"  # Change this path as needed

# Check if the VM list file exists
if (-Not (Test-Path -Path $vmListFile)) {
    Write-Host "Error: VM list file not found. Please check the path." -ForegroundColor Red
    exit
}

# Initialize an array to store the results
$pingResults = @()

# Read the VM names from the text file
$vmNames = Get-Content -Path $vmListFile

# Loop through each VM name
foreach ($vmName in $vmNames) {
    # Trim any leading or trailing whitespace
    $vmName = $vmName.Trim()

    # Skip empty lines or comments
    if ($vmName -eq "" -or $vmName.StartsWith("#")) {
        continue
    }

    # Try to resolve the IP address of the VM using DNS
    try {
        $ipAddress = [System.Net.Dns]::GetHostAddresses($vmName) | Select-Object -First 1
    }
    catch {
        Write-Host "Error: Unable to resolve IP for $vmName" -ForegroundColor Yellow
        $ipAddress = "N/A"
    }

    # Attempt to ping the VM
    $pingResult = Test-Connection -ComputerName $vmName -Count 1 -Quiet

    # Prepare the result object
    $result = New-Object PSObject -property @{
        VMName      = $vmName
        IPAddress   = $ipAddress
        PingStatus  = if ($pingResult) { "Successful" } else { "Failed" }
    }

    # Add the result to the results array
    $pingResults += $result
}

# Output the results to a CSV file
$pingResults | Export-Csv -Path $outputCsvFile -NoTypeInformation -Force

Write-Host "Ping status check complete. Results saved to: $outputCsvFile" -ForegroundColor Green
