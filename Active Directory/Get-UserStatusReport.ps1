<#
.SYNOPSIS
    This script checks the account status (Enabled/Disabled/Not Found) of a list of users against multiple Active Directory domains and exports the results to a CSV file.

.DESCRIPTION
    The script reads a list of usernames from an input file, attempts to retrieve their status (Enabled/Disabled) from multiple Active Directory domains, and generates a report.
    The results are exported to a CSV file, including the domain, username, and status.

.PARAMETER userListPath
    The path to the input file containing the list of usernames (Network IDs).

.PARAMETER outputCsvPath
    The path where the results will be exported in CSV format.

.PARAMETER domains
    A hardcoded list of Active Directory domains to check. You may modify this array as needed.

.EXAMPLE
    .\Get-UserStatusReport.ps1
    This will generate a report for the users listed in `.\users.txt` and export the results to `.\UserStatusReport.csv`.
#>

# Define the path to the input file containing usernames (Network IDs)
$userListPath = ".\users.txt"

# Define the path for the output CSV file where the report will be saved
$outputCsvPath = ".\UserStatusReport.csv"

# Define the list of Active Directory domains to search for user accounts
$domains = @(
    "APAC",
    "EMEA",
    "GLOBAL",
    "CORP",
    "AMER"
)

# Check if the input file exists
if (!(Test-Path $userListPath)) {
    Write-Host "Error: User list file not found: $userListPath" -ForegroundColor Red
    exit 1
}

# Initialize an array to store the results
$results = @()

# Read all usernames from the input file, ignoring empty lines
$usernames = Get-Content $userListPath | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }

# Get the total number of users to process
$totalUsers = $usernames.Count
$current = 0

# Display a message indicating the number of users being processed
Write-Host "Processing $totalUsers users..."

# Loop through each username from the list
foreach ($username in $usernames) {
    $current++
    $username = $username.Trim()
    $found = $false

    # Loop through each domain in the domains list to check user status
    foreach ($domain in $domains) {
        try {
            # Attempt to get the user account from the specified domain
            $user = Get-ADUser -Identity $username -Server $domain -Properties Enabled -ErrorAction Stop

            # Determine if the user account is enabled or disabled
            $status = if ($user.Enabled) { "Enabled" } else { "Disabled" }

            # Add the result to the results array
            $results += [PSCustomObject]@{
                Domain   = $domain
                Username = $username
                Status   = $status
            }

            # Display the result to the console
            Write-Host "[$current/$totalUsers] $domain\$username : $status" -ForegroundColor Green

            $found = $true
            break
        }
        catch {
            $errorMsg = $_.Exception.Message

            if ($errorMsg -notlike "*cannot find*") {
                # Log unexpected errors
                $results += [PSCustomObject]@{
                    Domain   = $domain
                    Username = $username
                    Status   = "Error: $errorMsg"
                }

                Write-Host "[$current/$totalUsers] $domain\$username : Error - $errorMsg" -ForegroundColor Yellow

                $found = $true
                break
            }
        }
    }

    # If user was not found in any domain
    if (-not $found) {
        $results += [PSCustomObject]@{
            Domain   = "N/A"
            Username = $username
            Status   = "Not Found"
        }

        Write-Host "[$current/$totalUsers] $username : Not Found" -ForegroundColor Yellow
    }
}

# Export the results array to a CSV file
$results | Export-Csv -Path $outputCsvPath -NoTypeInformation -Encoding UTF8

# Display a message indicating the report has been generated
Write-Host "User status report generated at: $outputCsvPath" -ForegroundColor Cyan
