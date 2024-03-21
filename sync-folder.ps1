Function Write-Log
{

<#
    .SYNOPSIS
    Writes log file

    .DESCRIPTION
    Creates daily log files according to the severity of the message.
    File creation/copying/removal operations are logged to a file as well to the console output.
    
    .PARAMETER Logpath

    .PARAMETER Type
    Defines the severity and action performed: "INFO","ADDITION","DELETION", "WARNING", "ERROR"

    .PARAMETER Message

    .EXAMPLE
    Write-Log -logpath $logpath -type INFO -message "Starting '$($source)' to '$($dest)' folder sync"

    .OUTPUT
    log file. console

    .EXAMPLE
    Write-Log -logpath $logpath -type ERROR -message "$_.Exception.Message"
#>

  	[CmdletBinding()]
	Param (
    [Parameter(Mandatory=$true)]
	[string]$logpath,
	[Parameter(Mandatory=$true)]
    [ValidateSet("INFO","ADDITION","DELETION","WARNING", "ERROR")]  
    [string]$type,
    [Parameter(Mandatory=$true)]
	[string]$message)
	
Process {
	$logfullpath = "$($logpath)\$(([DateTime]::Now).ToString("ddMMyyyy"))_$(Split-Path $source -Leaf)_folder_sync.log"
	Tee-Object -FilePath $logfullpath -InputObject "$(([DateTime]::Now).ToString('HH:mm:ss')) [$($type)] $($message)" -Append
	}
}

Function Sync-Folder
{
<#
    .SYNOPSIS
    Function to replicate and sync content of a folder (one direction)

    .DESCRIPTION
    Very basic script leveraging System.IO .NET Class to synchronize two folders (one direction).
    The script maintains a full, identical copy of source folder at destination path.
   
    Needs improvements:
    -Compare the folder and file content based on a hash leveraging get-filehash and compare-object cmdlets. This is to handle renames on source location.
    -Compare and replicate the NTFS permissions and file ownership. In case the permissions have been changed at the source location.
    
    .PARAMETER Source
    Describes the source folder to be replicated from
    
    .PARAMETER Dest
    Describes the target folder to be replicated to

    .PARAMETER Logfolder
    Describes the log folder

    .EXAMPLE
    Sync-Folder -source "C:\test\source" -dest "C:\test\replica" -logfolder "C:\test\log"

    .NOTES
    https://github.com/KornKolio/folder_sync
#>

  	[CmdletBinding()]
	Param (
    [Parameter(Mandatory=$true)]
	[string]$source,
	[Parameter(Mandatory=$true)]
    [string]$dest,
    [Parameter(Mandatory=$true)]
	[string]$logfolder)

BEGIN {
Write-Log -logpath $logfolder -type INFO -message "Starting '$($source)' to '$($dest)' folder replication"
}

PROCESS {

#Create destination folder if dosen't exist
If (!([System.IO.Directory]::Exists($dest))) {

try {
[System.IO.Directory]::CreateDirectory($dest)
Write-Log -logpath $logfolder -type INFO -message "Destination folder doesn't exist. Creating $($dest)"
}
catch {
Write-Log -logpath $logpath -type ERROR -message "The target directory cannot be created: $($_.Exception.Message)"
    }
}

# ================== Additions ===================


#Enumerate the source directories and replicate to destination
try {
[System.IO.Directory]::EnumerateDirectories($source,"*","AllDirectories") | % {
$destdir = [System.IO.Directory]::Exists($_.Replace($source,$dest))
If (!($destdir)) {[System.IO.Directory]::CreateDirectory($_.Replace($source,$dest))
Write-Log -logpath $logfolder -type ADDITION -message "'$($_)' folder doesn't exist on destination. Creating '$($_.Replace($source,$dest))'"
}
    }
}
catch {
Write-Log -logpath $logpath -type ERROR -message "$_.Exception.Message"
}

#Enumerate the source files and replicate to destination

try {
[System.IO.Directory]::EnumerateFiles($source,"*","AllDirectories") | % {
$destfile = [System.IO.File]::Exists($_.Replace($source,$dest))
If (!($destfile)) {[System.IO.File]::Copy($_,$_.Replace($source,$dest),$true)
Write-Log -logpath $logfolder -type ADDITION -message "'$($_)' file doesn't exist on destination. Creating '$($_.Replace($source,$dest))'"
}
    }
}
catch {
Write-Log -logpath $logpath -type ERROR -message "$_.Exception.Message"
}

# ================== Removals ===================

#Compare the folder content and perfrom removals on destination

try {
[System.IO.Directory]::EnumerateDirectories($dest,"*","AllDirectories") | % {
$sourcedir = [System.IO.Directory]::Exists($_.Replace($dest,$source))
If (!($sourcedir)) {[System.IO.Directory]::Delete($_,$true)
Write-Log -logpath $logfolder -type DELETION -message "'$($_)' folder doesn't exist on source. Deleting '$($_)'"
}
    }
}
catch {
Write-Log -logpath $logpath -type ERROR -message "$_.Exception.Message"
}

#Compare the file content and perfrom removals on destination

try {
[System.IO.Directory]::EnumerateFiles($dest,"*","AllDirectories") | % {
$sourcefile = [System.IO.File]::Exists($_.Replace($dest,$source))
If (!($sourcefile)) {[System.IO.File]::Delete($_)
Write-Log -logpath $logfolder -type DELETION -message "'$($_)' file doesn't exist on source. Deleting '$($_)'"
}
    }
}
catch {
Write-Log -logpath $logpath -type ERROR -message "$_.Exception.Message"
    }
} #end process

END {
Write-Log -logpath $logfolder -type INFO -message "The replication of '$($source)' to '$($dest)' folder has been completed."
}

} #end function

#Sync-Folder -source "C:\test\source" -dest "C:\test\replica" -logfolder "C:\test\log"