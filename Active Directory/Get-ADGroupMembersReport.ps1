#Requires -Modules ActiveDirectory
<#
.SYNOPSIS
    Exports the members of one or more AD groups to CSV.

.DESCRIPTION
    For each group, lists members with their type and (for users) enabled state and
    email. -Recursive expands nested groups. Groups that cannot be found are
    reported as a warning and skipped, not treated as a fatal error.

.PARAMETER GroupName
    One or more group names (sAMAccountName, DN, SID or GUID).

.PARAMETER Recursive
    Expand nested group membership.

.PARAMETER Server
    Optional domain controller / domain to query.

.PARAMETER OutputCsvPath
    CSV output path. Defaults to a timestamped file in the current folder.

.EXAMPLE
    .\Get-ADGroupMembersReport.ps1 -GroupName 'Domain Admins','VPN-Users' -Recursive
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory, ValueFromPipeline)]
    [string[]]$GroupName,

    [switch]$Recursive,

    [string]$Server,

    [string]$OutputCsvPath = ".\ADGroupMembers_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"
)

begin {
    $rows = [System.Collections.Generic.List[object]]::new()
    $base = @{ ErrorAction = 'Stop' }
    if ($Server) { $base.Server = $Server }
}

process {
    foreach ($group in $GroupName) {
        try {
            $members = @(Get-ADGroupMember -Identity $group -Recursive:$Recursive @base)
        }
        catch {
            Write-Warning "Group '$group': $($_.Exception.Message)"
            continue
        }

        Write-Host "$group : $($members.Count) member(s)" -ForegroundColor Cyan

        foreach ($m in $members) {
            $enabled = $null
            $mail    = $null
            if ($m.objectClass -eq 'user') {
                try {
                    $u       = Get-ADUser -Identity $m.distinguishedName -Properties Mail, Enabled @base
                    $enabled = $u.Enabled
                    $mail    = $u.Mail
                }
                catch { Write-Verbose "Could not read user details for $($m.SamAccountName)" }
            }

            $rows.Add([PSCustomObject]@{
                Group          = $group
                Name           = $m.name
                SamAccountName = $m.SamAccountName
                ObjectClass    = $m.objectClass
                Enabled        = $enabled
                Mail           = $mail
                Recursive      = [bool]$Recursive
            })
        }
    }
}

end {
    if ($rows.Count -eq 0) {
        Write-Warning 'No members found; nothing exported.'
        return
    }
    $rows | Export-Csv -Path $OutputCsvPath -NoTypeInformation -Encoding UTF8
    Write-Host "Exported $($rows.Count) row(s) to: $OutputCsvPath" -ForegroundColor Cyan
}
