# folder_sync
    .SYNOPSIS
    Function to sync content of a folder (one direction)

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
    Describes the log folder path

    .EXAMPLE
    Sync-Folder -source "C:\test\source" -dest "C:\test\replica" -logfolder "C:\test\log"
