<#
.SYNOPSIS
    Reads a list of email addresses from a file and retrieves corresponding sAMAccountNames (Network IDs) from Active Directory.

.DESCRIPTION
    For each email in the input file:
    - Looks up the user in Active Directory by the "mail" attribute.
    - Extracts the sAMAccountName.
    - Saves the results to an output CSV-formatted text file.
    - Displays real-time progress in the console.

.NOTES
    Requires:
    - Active Directory module (RSAT or domain-joined environment).
    - Proper permissions to query AD.
#>

# ----------- CONFIGURE INPUT/OUTPUT FILE PATHS -----------
$emailFilePath  = "C:\Path\To\email.txt"               # Path to input file containing one email per line
$outputFilePath = "C:\Path\To\EmailsOutput.txt"        # Path to save the output results (CSV format)
# ---------------------------------------------------------

# Import Active Directory module (make sure it's available)
Import-Module ActiveDirectory -ErrorAction Stop

# Check if input file exists
if (Test-Path $emailFilePath) {
    # Read email addresses
    $emails = Get-Content -Path $emailFilePath

    # Initialize output array to collect results
    $output = @()

    # Initialize progress tracking
    $counter = 1
    $total = $emails.Count

    # Process each email
    foreach ($email in $emails) {
        $trimmedEmail = $email.Trim()

        # Skip empty lines
        if (-not [string]::IsNullOrWhiteSpace($trimmedEmail)) {
            Write-Host "[$counter/$total] Processing: $trimmedEmail"

            try {
                # Query AD user by email (mail attribute)
                $adUser = Get-ADUser -Filter { Mail -eq $trimmedEmail } -Properties Mail, sAMAccountName

                if ($adUser) {
                    # User found, add to output
                    $output += [PSCustomObject]@{
                        Email          = $trimmedEmail
                        SAMAccountName = $adUser.sAMAccountName
                    }
                    Write-Host "     ✔ Found: $($adUser.sAMAccountName)" -ForegroundColor Green
                }
                else {
                    # User not found
                    $output += [PSCustomObject]@{
                        Email          = $trimmedEmail
                        SAMAccountName = "Not Found"
                    }
                    Write-Host "     ✖ Not Found in AD" -ForegroundColor Yellow
                }
            }
            catch {
                # Error during lookup
                $output += [PSCustomObject]@{
                    Email          = $trimmedEmail
                    SAMAccountName = "Error: $_"
                }
                Write-Host "     ⚠ Error: $_" -ForegroundColor Red
            }

            $counter++
        }
    }

    # Export results to a CSV-formatted .txt file
    $output | Export-Csv -Path $outputFilePath -NoTypeInformation
    Write-Host "`n✅ Output saved to: $outputFilePath`n" -ForegroundColor Cyan
}
else {
    Write-Host "`n❌ File not found: $emailFilePath`n" -ForegroundColor Red
}
