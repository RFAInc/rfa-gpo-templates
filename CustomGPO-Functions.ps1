function Import-CustomGPO {
    <#
    .SYNOPSIS
        This function creates a GPO from an existing GPO backup hereby reffered to as a "template"
    .NOTES
        Version:        1.6
        Author:         Andy Escolastico
        Creation Date:  11/11/2019
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [String]$BackupName,

        [Parameter(Mandatory=$true)]
        [String]$BackupPath,
        
        [Parameter(Mandatory=$true)]
        [String]$GPOName,
        
        [Parameter(Mandatory=$false)]
        [String]$LinkPath = (Get-AdDomain).DistinguishedName,
        
        [Parameter(Mandatory=$true)]
        [String]$FilterGroup
    )
    # creates new gpo using template 
    try {
        $import_result = Import-GPO -BackupGPOName $BackupName -TargetName $GPOName -Path $BackupPath -CreateIfNeeded -ErrorAction "Stop"
        Write-Host "Imported `"$($import_result.DisplayName)`" to `"$($import_result.DomainName)`""
        # links new gpo to domain
        try {
            $link_result = New-GPLink -Name $GPOName -Target $LinkPath -ErrorAction "Stop"
            Write-Host "Linked `"$($link_result.DisplayName)`" to `"$($link_result.Target)`""
        }
        catch [System.ArgumentException] {
            Write-Host "GPO does not exist or its already linked"
        }
        catch {
            Write-Host "Link apply failed for GPO $GPOName to the path $LinkPath. Please ensure it gets applied manually."
        }
        # applies security filtering
        try {
            $filtering_result = Set-GPPermission -Name $GPOName -TargetName $FilterGroup -TargetType "Group" -PermissionLevel "GpoApply" -ErrorAction "Stop"
            Write-Host "Filtered `"$($filtering_result.DisplayName)`" to `"$FilterGroup`""
        }
        catch [System.ArgumentException] {
            Write-Host "GPO does not exist"
        }
        catch {
            Write-Host "Filter apply failed for GPO $GPOName to the group $FilterGroup. Please ensure it gets applied manually."
        }
    }
    catch [UnauthorizedAccessException]{
        Write-Host "Insufficient access, cannot create GPO"
    }
    catch {
        Write-Output "GPO import failed for backup $BackupName."
    }
}
function New-CustomGPO {
    <#
    .SYNOPSIS
        This function creates a GPO from the registry specification passed to it as a param. It can only be defined by registry based policies and nothing else.
        This is a limitation of the "New-GPO" standard lib function.
    .NOTES
        Version:        1.6
        Author:         Andy Escolastico
        Creation Date:  11/11/2019
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [String]$GPOName,
        [Parameter(Mandatory=$false)]
        [String]$LinkPath = (Get-AdDomain).DistinguishedName,
        [Parameter(Mandatory=$true)]
        [String]$RegKey,
        [Parameter(Mandatory=$true)]
        [String]$RegSubKey,
        [Parameter(Mandatory=$true)]
        [String]$RegType,
        [Parameter(Mandatory=$true)]
        [Int]$RegValue,
        [Parameter(Mandatory=$true)]
        [String]$FilterGroup
    )
    # creates new gpo using template 
    try {
        $create_result = New-GPO -Name $GPOName -ErrorAction "Stop" 
        Write-Host "Created `"$($create_result.DisplayName)`" in `"$($create_result.DomainName)`""
        # configures gpo with registry settings
        try {
            $configure_result = Set-GPRegistryValue -Name $GPOName -Key $RegKey -ValueName $RegSubKey -Type $RegType -Value $RegValue -ErrorAction "Stop"
            Write-Host "Configured `"$($configure_result.DisplayName)`" with `"$RegKey : $RegSubKey : $RegValue ($RegType)`""
        }
        catch [System.ArgumentException]{
            Write-Host "GPO does not exist"
        }
        catch {
            Write-Host "GPO configuration failed"
        }
        # links new gpo to domain
        try {
            $link_result = New-GPLink -Name $GPOName -Target $LinkPath -ErrorAction "Stop"
            Write-Host "Linked `"$($link_result.DisplayName)`" to `"$($link_result.Target)`""
        }
        catch [System.ArgumentException] {
            Write-Host "GPO does not exist or its already linked"
        }
        catch {
            Write-Host "GPO link failed"
        }
        # applies security filtering
        try {
            $filtering_result = Set-GPPermission -Name $GPOName -TargetName $FilterGroup -TargetType "Group" -PermissionLevel "GpoApply" -ErrorAction "Stop"
            Write-Host "Filtered `"$($filtering_result.DisplayName)`" to `"$FilterGroup`""
        }
        catch [System.ArgumentException] {
            Write-Host "GPO does not exist"
        }
        catch {
            Write-Host "Filter set failed"
        }
    }
    catch [UnauthorizedAccessException]{
        Write-Host "Insufficient access, cannot create GPO"
    }
    catch [System.ArgumentException]{
        Write-Host "GPO already exists"
    }
    catch {
        Write-Host "GPO creation failed"
    }
}
