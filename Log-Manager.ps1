<#PSScriptInfo

.VERSION 21.12.09

.GUID 109eb5a2-1dd4-4def-9b9e-1d7413c8697f

.AUTHOR Mike Galvin Contact: mike@gal.vin / twitter.com/mikegalvin_ / discord.gg/5ZsnJ5k

.COMPANYNAME Mike Galvin

.COPYRIGHT (C) Mike Galvin. All rights reserved.

.TAGS Log Manager Clean up Backup Zip History MDT Microsoft Deployment Toolkit IIS Internet Information Services

.LICENSEURI

.PROJECTURI https://gal.vin/posts/powershell-log-manager/

.ICONURI

.EXTERNALMODULEDEPENDENCIES 

.REQUIREDSCRIPTS

.EXTERNALSCRIPTDEPENDENCIES

.RELEASENOTES

#>

<#
    .SYNOPSIS
    Log Manager Utility - Flexible clean up and backup of log files.

    .DESCRIPTION
    This utility will delete files and folders older than X days.
    It can also backup files and folders older than X days to another location.

    To send a log file via e-mail using ssl and an SMTP password you must generate an encrypted password file.
    The password file is unique to both the user and machine.
    To create the password file run this command as the user and on the machine that will use the file:

    $creds = Get-Credential
    $creds.Password | ConvertFrom-SecureString | Set-Content C:\scripts\ps-script-pwd.txt

    .PARAMETER LogsPath
    The path that contains the logs that the utility should process.

    .PARAMETER LogKeep
    Instructs the utility to keep a specified number of days’ worth of logs.
    Logs older than the number of days specified will be deleted.

    .PARAMETER BackupTo
    The path the logs should be backed up to.
    A folder will be created inside this location.
    Do not add a trailing backslash.
    If this option is not used, backup will not be performed.

    .PARAMETER BacKeep
    Instructs the utility to keep a specified number of days’ worth of backups.
    Backups older than the number of days specified will be deleted.
    Only backup folders or zip files created by this utility will be removed.

    .PARAMETER Compress
    This option will create a zip file of the log files.

    .PARAMETER Wd
    The path to the working directory to use for the backup before copying it to the final backup directory.
    Use a directory on local fast media to improve performance.

    .PARAMETER ZipName
    Enter the name of the zip file you wish to have.
    If the name includes a space, encapsulate with single quotes.
    The time and date will be appended to this name.
    If this option is not used, a default name of logs-HOSTNAME-date-time.zip will be used.

    .PARAMETER Sz
    Configure the utility to use 7-Zip to compress the log files.
    7-Zip must be installed in the default location ($env:ProgramFiles) if it is not found, Windows compression will be used as a fallback.

    .PARAMETER NoBanner
    Use this option to hide the ASCII art title in the console.

    .PARAMETER L
    The path to output the log file to.
    The file name will be Log-Man_YYYY-MM-dd_HH-mm-ss.log
    Do not add a trailing \ backslash.

    .PARAMETER Subject
    The subject line for the e-mail log. Encapsulate with single or double quotes.
    If no subject is specified, the default of "Log Manager Utility Log" will be used.

    .PARAMETER SendTo
    The e-mail address the log should be sent to.

    .PARAMETER From
    The e-mail address the log should be sent from.

    .PARAMETER Smtp
    The DNS name or IP address of the SMTP server.

    .PARAMETER Port
    The Port that should be used for the SMTP server.

    .PARAMETER User
    The user account to authenticate to the SMTP server.

    .PARAMETER Pwd
    The txt file containing the encrypted password for SMTP authentication.

    .PARAMETER UseSsl
    Configures the utility to connect to the SMTP server using SSL.

    .EXAMPLE
    Log-Manager.ps1 -LogsPath C:\inetpub\logs\LogFiles\W3SVC*\* -LogKeep 30 -BackupTo \\nas\archive -BacKeep 30
    -Wd C:\temp -Compress -L C:\scripts\logs -Subject 'Server: Log Manager' -SendTo me@contoso.com
    -From Log-Manager@contoso.com -Smtp smtp.outlook.com -User me@contoso.com -Pwd c:\scripts\ps-script-pwd.txt -UseSsl

    The above command will backup and remove IIS logs older than 30 days. It will create a zip folder using the
    C:\temp folder as a working directory and the file will be stored in \\nas\archive.
    The log file will be output to C:\scripts\logs and sent via e-mail with a custom subject line.
#>

## Set up command line switches.
[CmdletBinding()]
Param(
    [parameter(Mandatory=$True)]
    [alias("LogsPath")]
    $Source,
    [alias("LogKeep")]
    $LogHistory,
    [alias("BackupTo")]
    [ValidateScript({Test-Path $_ -PathType 'Container'})]
    $Backup,
    [alias("BacKeep")]
    $BacHistory,
    [alias("Wd")]
    [ValidateScript({Test-Path $_ -PathType 'Container'})]
    $WorkDir,
    [alias("ZipName")]
    $ZName,
    [alias("L")]
    $LogPath,
    [alias("Subject")]
    $MailSubject,
    [alias("SendTo")]
    $MailTo,
    [alias("From")]
    $MailFrom,
    [alias("Smtp")]
    $SmtpServer,
    [alias("Port")]
    $SmtpPort,
    [alias("User")]
    $SmtpUser,
    [alias("Pwd")]
    [ValidateScript({Test-Path -Path $_ -PathType Leaf})]
    $SmtpPwd,
    [switch]$UseSsl,
    [switch]$Compress,
    [switch]$Sz,
    [switch]$NoBanner)

If ($NoBanner -eq $False)
{
    Write-Host -Object ""
    Write-Host -ForegroundColor Yellow -BackgroundColor Black -Object "                                                                       "
    Write-Host -ForegroundColor Yellow -BackgroundColor Black -Object "   __    _____  ___    __  __    __    _  _    __    ___  ____  ____   "
    Write-Host -ForegroundColor Yellow -BackgroundColor Black -Object "  (  )  (  _  )/ __)  (  \/  )  /__\  ( \( )  /__\  / __)( ___)(  _ \  "
    Write-Host -ForegroundColor Yellow -BackgroundColor Black -Object "   )(__  )(_)(( (_-.   )    (  /(__)\  )  (  /(__)\( (_-. )__)  )   /  "
    Write-Host -ForegroundColor Yellow -BackgroundColor Black -Object "  (____)(_____)\___/  (_/\/\_)(__)(__)(_)\_)(__)(__)\___/(____)(_)\_)  "
    Write-Host -ForegroundColor Yellow -BackgroundColor Black -Object "   __  __  ____  ____  __    ____  ____  _  _                          "
    Write-Host -ForegroundColor Yellow -BackgroundColor Black -Object "  (  )(  )(_  _)(_  _)(  )  (_  _)(_  _)( \/ )                         "
    Write-Host -ForegroundColor Yellow -BackgroundColor Black -Object "   )(__)(   )(   _)(_  )(__  _)(_   )(   \  /                          "
    Write-Host -ForegroundColor Yellow -BackgroundColor Black -Object "  (______) (__) (____)(____)(____) (__)  (__)                          "
    Write-Host -ForegroundColor Yellow -BackgroundColor Black -Object "                                                                       "
    Write-Host -ForegroundColor Yellow -BackgroundColor Black -Object "    Mike Galvin   https://gal.vin   Version 21.12.09                   "
    Write-Host -ForegroundColor Yellow -BackgroundColor Black -Object "                                                                       "
    Write-Host -Object ""
}

## If logging is configured, start logging.
## If the log file already exists, clear it.
If ($LogPath)
{
    ## Make sure the log directory exists.
    $LogPathFolderT = Test-Path $LogPath

    If ($LogPathFolderT -eq $False)
    {
        New-Item $LogPath -ItemType Directory -Force | Out-Null
    }

    $LogFile = ("Log-Man_{0:yyyy-MM-dd_HH-mm-ss}.log" -f (Get-Date))
    $Log = "$LogPath\$LogFile"

    $LogT = Test-Path -Path $Log

    If ($LogT)
    {
        Clear-Content -Path $Log
    }

    Add-Content -Path $Log -Encoding ASCII -Value "$(Get-Date -Format "yyyy-MM-dd HH:mm:ss") [INFO] Log started"
}

##
## Start of functions.
##

## Function to get date in specific format.
Function Get-DateFormat
{
    Get-Date -Format "yyyy-MM-dd HH:mm:ss"
}

## Function for logging.
Function Write-Log($Type, $Evt)
{
    If ($Type -eq "Info")
    {
        If ($Null -ne $LogPath)
        {
            Add-Content -Path $Log -Encoding ASCII -Value "$(Get-DateFormat) [INFO] $Evt"
        }
        
        Write-Host -Object "$(Get-DateFormat) [INFO] $Evt"
    }

    If ($Type -eq "Succ")
    {
        If ($Null -ne $LogPath)
        {
            Add-Content -Path $Log -Encoding ASCII -Value "$(Get-DateFormat) [SUCCESS] $Evt"
        }

        Write-Host -ForegroundColor Green -Object "$(Get-DateFormat) [SUCCESS] $Evt"
    }

    If ($Type -eq "Err")
    {
        If ($Null -ne $LogPath)
        {
            Add-Content -Path $Log -Encoding ASCII -Value "$(Get-DateFormat) [ERROR] $Evt"
        }

        Write-Host -ForegroundColor Red -BackgroundColor Black -Object "$(Get-DateFormat) [ERROR] $Evt"
    }

    If ($Type -eq "Conf")
    {
        If ($Null -ne $LogPath)
        {
            Add-Content -Path $Log -Encoding ASCII -Value "$Evt"
        }

        Write-Host -ForegroundColor Cyan -Object "$Evt"
    }
}

## Function for the options post backup.
Function OptionsRun
{
    ## If the -keep switch AND the -compress switch are NOT configured.
    If ($Null -eq $BacHistory -And $Compress -eq $False)
    {
        ## Remove all previous backup folders, including ones from previous versions of this script.
        try {
            Get-ChildItem -Path $WorkDir -Filter "$ZName-*-*-***-*-*" -Directory | Remove-Item -Recurse -Force
        }
        catch{
            $_.Exception.Message | Write-Log -Type Err -Evt $_
        }

        ## If a working directory is configured by the user, remove all previous backup folders, including
        ## ones from previous versions of this script.
        If ($WorkDir -ne $Backup)
        {
            try {
                Get-ChildItem -Path $Backup -Filter "$ZName-*-*-***-*-*" -Directory | Remove-Item -Recurse -Force
            }
            catch{
                $_.Exception.Message | Write-Log -Type Err -Evt $_
            }
        }

        Write-Log -Type Info -Evt "Removing previous backup folders"
    }

    ## If the -keep option IS configured AND the -compress option is NOT configured.
    else {
        If ($Compress -eq $False)
        {
            ## Remove previous backup folders older than the configured number of days, including
            ## ones from previous versions of this script.
            try {
                Get-ChildItem -Path $WorkDir -Filter "$ZName-*-*-***-*-*" -Directory | Where-Object CreationTime -lt (Get-Date).AddDays(-$BacHistory) | Remove-Item -Recurse -Force
            }
            catch{
                $_.Exception.Message | Write-Log -Type Err -Evt $_
            }

            ## If a working directory is configured by the user, remove previous backup folders
            ## older than the configured number of days remove all previous backup folders,
            ## including ones from previous versions of this script.
            If ($WorkDir -ne $Backup)
            {
                try {
                    Get-ChildItem -Path $Backup -Filter "$ZName-*-*-***-*-*" -Directory | Where-Object CreationTime -lt (Get-Date).AddDays(-$BacHistory) | Remove-Item -Recurse -Force
                }
                catch{
                    $_.Exception.Message | Write-Log -Type Err -Evt $_
                }
            }

            Write-Log -Type Info -Evt "Removing backup folders older than: $BacHistory days"
        }
    }

    ## Check to see if the -compress switch IS configured AND if the -keep switch is NOT configured.
    If ($Compress)
    {
        If ($Null -eq $BacHistory)
        {
            ## Remove all previous compressed backups, including ones from previous versions of this script.
            try {
                Remove-Item "$WorkDir\$ZName-*-*-***-*-*.zip" -Force
            }
            catch{
                $_.Exception.Message | Write-Log -Type Err -Evt $_
            }

            ## If a working directory is configured by the user, remove all previous compressed backups,
            ## including ones from previous versions of this script.
            If ($WorkDir -ne $Backup)
            {
                try {
                    Remove-Item "$Backup\$ZName-*-*-***-*-*.zip" -Force
                }
                catch{
                    $_.Exception.Message | Write-Log -Type Err -Evt $_
                }
            }

            Write-Log -Type Info -Evt "Removing previous compressed backups"
        }

        ## If the -compress switch IS configured AND if the -keep switch IS configured.
        else {
            ## Remove previous compressed backups older than the configured number of days, including
            ## ones from previous versions of this script.
            try {
                Get-ChildItem -Path "$WorkDir\$ZName-*-*-***-*-*.zip" | Where-Object CreationTime -lt (Get-Date).AddDays(-$BacHistory) | Remove-Item -Force
            }
            catch{
                $_.Exception.Message | Write-Log -Type Err -Evt $_
            }

            ## If a working directory is configured by the user, remove previous compressed backups older
            ## than the configured number of days, including ones from previous versions of this script.
            If ($WorkDir -ne $Backup)
            {
                try {
                    Get-ChildItem -Path "$Backup\$ZName-*-*-***-*-*.zip" | Where-Object CreationTime -lt (Get-Date).AddDays(-$BacHistory) | Remove-Item -Force
                }
                catch{
                    $_.Exception.Message | Write-Log -Type Err -Evt $_
                }
            }

            Write-Log -Type Info -Evt "Removing compressed backups older than: $BacHistory days"
        }

        ## If the -compress switch and the -Sz switch IS configured, test for 7zip being installed.
        ## If it is, compress the backup folder, if it is not use Windows compression.
        If ($Sz -eq $True)
        {
            $7zT = Test-Path "$env:programfiles\7-Zip\7z.exe"
            If ($7zT -eq $True)
            {
                Write-Log -Type Info -Evt "Compressing using 7-Zip compression"

                try {
                    & "$env:programfiles\7-Zip\7z.exe" -bso0 a -tzip ("$WorkDir\$ZName-{0:yyyy-MM-dd_HH-mm-ss}.zip" -f (Get-Date)) "$WorkDir\$ZName\*"
                }
                catch{
                    $_.Exception.Message | Write-Log -Type Err -Evt $_
                }
            }

            else {
                Write-Log -Type Info -Evt "Compressing using Windows compression"
                Add-Type -AssemblyName "system.io.compression.filesystem"
                try {
                    [io.compression.zipfile]::CreateFromDirectory("$WorkDir\$ZName", ("$WorkDir\$ZName-{0:yyyy-MM-dd_HH-mm-ss}.zip" -f (Get-Date)))
                }
                catch{
                    $_.Exception.Message | Write-Log -Type Err -Evt $_
                }
            }
        }

        ## If the -compress switch IS configured and the -Sz switch is NOT configured, compress
        ## the backup folder using Windows compression.
        else {
            Write-Log -Type Info -Evt "Compressing using Windows compression"
            Add-Type -AssemblyName "system.io.compression.filesystem"
            [io.compression.zipfile]::CreateFromDirectory("$WorkDir\$ZName", ("$WorkDir\$ZName-{0:yyyy-MM-dd_HH-mm-ss}.zip" -f (Get-Date)))
        }

        ## Clean up
        try {
            Get-ChildItem -Path $WorkDir -Filter "$ZName" -Directory | Remove-Item -Recurse -Force
        }
        catch{
            $_.Exception.Message | Write-Log -Type Err -Evt $_
        }

        ## If a working directory has been configured by the user, move the compressed
        ## backup to the backup location and rename to include the date.
        If ($WorkDir -ne $Backup)
        {
            try {
                Get-ChildItem -Path $WorkDir -Filter "$ZName-*-*-*-*-*.zip" | Move-Item -Destination $Backup
            }
            catch{
                $_.Exception.Message | Write-Log -Type Err -Evt $_
            }
        }
    }

    ## If the -compress switch is NOT configured AND if the -keep switch is NOT configured, rename
    ## the backup folder to include the date.
    else {
        try {
            Get-ChildItem -Path $WorkDir -Filter $ZName -Directory | Rename-Item -NewName ("$WorkDir\$ZName-{0:yyyy-MM-dd_HH-mm-ss}" -f (Get-Date))
        }
        catch{
            $_.Exception.Message | Write-Log -Type Err -Evt $_
        }

        If ($WorkDir -ne $Backup)
        {
            try {
                Get-ChildItem -Path $WorkDir -Filter "$ZName-*-*-***-*-*" -Directory | Move-Item -Destination ("$Backup\$ZName-{0:yyyy-MM-dd_HH-mm-ss}" -f (Get-Date))
            }
            catch{
                $_.Exception.Message | Write-Log -Type Err -Evt $_
            }
        }
    }
}

##
## End of functions.
##

##
## Start main process.
##

## getting Windows Version info
$OSVMaj = [environment]::OSVersion.Version | Select-Object -expand major
$OSVMin = [environment]::OSVersion.Version | Select-Object -expand minor
$OSVBui = [environment]::OSVersion.Version | Select-Object -expand build
$OSV = "$OSVMaj" + "." + "$OSVMin" + "." + "$OSVBui"

##
## Display the current config and log if configured.
##

Write-Log -Type Conf -Evt "************ Running with the following config *************."
Write-Log -Type Conf -Evt "Utility Version:.......21.12.09"
Write-Log -Type Conf -Evt "Hostname:..............$Env:ComputerName."
Write-Log -Type Conf -Evt "Windows Version:.......$OSV."
Write-Log -Type Conf -Evt "Path to process:.......$Source."
Write-Log -Type Conf -Evt "Logs to keep:..........$LogHistory days"

If ($Backup)
{
    Write-Log -Type Conf -Evt "Backup directory:......$Backup."
    Write-Log -Type Conf -Evt "Working directory:.....$WorkDir."
    Write-Log -Type Conf -Evt "Backups to keep:.......$BacHistory days"
    Write-Log -Type Conf -Evt "Zip file name:.........$ZName + date and time."
}

else {
    Write-Log -Type Conf -Evt "Backup directory:......No Config"
    Write-Log -Type Conf -Evt "Working directory:.....No Config"
    Write-Log -Type Conf -Evt "Backups to keep:.......No Config"
    Write-Log -Type Conf -Evt "Zip file name:.........No Config"
}

If ($LogPath)
{
    Write-Log -Type Conf -Evt "Log directory:.........$LogPath."
}

else {
    Write-Log -Type Conf -Evt "Log directory:.........No Config"
}

If ($MailTo)
{
    Write-Log -Type Conf -Evt "E-mail log to:.........$MailTo."
}

else {
    Write-Log -Type Conf -Evt "E-mail log to:.........No Config"
}

If ($MailFrom)
{
    Write-Log -Type Conf -Evt "E-mail log from:.......$MailFrom."
}

else {
    Write-Log -Type Conf -Evt "E-mail log from:.......No Config"
}

If ($MailSubject)
{
    Write-Log -Type Conf -Evt "E-mail subject:........$MailSubject."
}

else {
    Write-Log -Type Conf -Evt "E-mail subject:........Default"
}

If ($SmtpServer)
{
    Write-Log -Type Conf -Evt "SMTP server:...........$SmtpServer."
}

else {
    Write-Log -Type Conf -Evt "SMTP server:...........No Config"
}

If ($SmtpPort)
{
    Write-Log -Type Conf -Evt "SMTP Port:.............$SmtpPort."
}

else {
    Write-Log -Type Conf -Evt "SMTP Port:.............Default"
}

If ($SmtpUser)
{
    Write-Log -Type Conf -Evt "SMTP user:.............$SmtpUser."
}

else {
    Write-Log -Type Conf -Evt "SMTP user:.............No Config"
}

If ($SmtpPwd)
{
    Write-Log -Type Conf -Evt "SMTP pwd file:.........$SmtpPwd."
}

else {
    Write-Log -Type Conf -Evt "SMTP pwd file:.........No Config"
}

Write-Log -Type Conf -Evt "-UseSSL switch:........$UseSsl."
Write-Log -Type Conf -Evt "-Compress switch:......$Compress."
Write-Log -Type Conf -Evt "-Sz switch:............$Sz."
Write-Log -Type Conf -Evt "************************************************************"
Write-Log -Type Info -Evt "Process started"

##
## Display current config ends here.
##

## Count the number of files that are old enough to work on in the configured directory
## If the number of the files to work on is not zero then proceed.
$FileNo = Get-ChildItem -Path $Source -Recurse | Where-Object CreationTime -lt (Get-Date).AddDays(-$LogHistory) | Measure-Object

If ($FileNo.count -ne 0)
{
    ## If time -days switch isn't configured, then set it to 0
    If ($Null -eq $LogHistory)
    {
        $LogHistory = "0"
    }

    If ($Null -eq $BacHistory)
    {
        $BacHistory = "0"
    }

    ## If the user has not configured the working directory, set it as the backup directory if needed.
    If ($Null -ne $Backup)
    {
        If ($Null -eq $WorkDir)
        {
            $WorkDir = "$Backup"
        }
    }

    ## If the user has not configured a zip name, set it as the default.
    If ($Null -eq $ZName)
    {
        $ZName = "Logs-$env:computername"
    }

    Write-Log -Type Info -Evt "The following objects will be processed:"
    Get-ChildItem -Path $Source | Select-Object -ExpandProperty Name

    If ($LogPath)
    {
        Get-ChildItem -Path $Source | Select-Object -ExpandProperty Name | Out-File -Append $Log -Encoding ASCII
    }

    If ($Backup)
    {
        ## Test for the existence of a previous backup. If it exists, delete it.
        $BackupT = Test-Path "$WorkDir\$ZName"
        If ($BackupT -eq $True)
        {
            try {
                Remove-Item "$WorkDir\$ZName" -Recurse -Force
            }
            catch{
                $_.Exception.Message | Write-Log -Type Err -Evt $_
            }
        }

        Write-Log -Type Info -Evt "Attempting to move objects older than: $LogHistory days"

        try {
            New-Item -Path "$WorkDir\$ZName" -ItemType Directory | Out-Null
            Get-ChildItem -Path $Source | Where-Object CreationTime -lt (Get-Date).AddDays(-$LogHistory) | Copy-Item -Destination "$WorkDir\$ZName" -Recurse -Force
        }
        catch{
            $_.Exception.Message | Write-Log -Type Err -Evt $_
        }

        OptionsRun
    }

    ## If no backup options were configured, or after doing the previous operations, remove the old files.
    Get-ChildItem -Path $Source | Where-Object CreationTime -lt (Get-Date).AddDays(-$LogHistory) | Remove-Item -Recurse
    Write-Log -Type Info -Evt "Deleting logs older than: $LogHistory days"

    ##
    ## Main process ends here.
    ##
}

## If there are no objects old enough to process then finish.
else {
    Write-Log -Type Info -Evt "There are no objects to process."
}

Write-Log -Type Info -Evt "Process finished."

## If logging is configured then finish the log file.
If ($LogPath)
{
    Add-Content -Path $Log -Encoding ASCII -Value "$(Get-Date -Format "yyyy-MM-dd HH:mm:ss") [INFO] Log finished"

    ## This whole block is for e-mail, if it is configured.
    If ($SmtpServer)
    {
        ## Default e-mail subject if none is configured.
        If ($Null -eq $MailSubject)
        {
            $MailSubject = "Log Manager Utility Log"
        }

        ## Default Smtp Port if none is configured.
        If ($Null -eq $SmtpPort)
        {
            $SmtpPort = "25"
        }

        ## Setting the contents of the log to be the e-mail body. 
        $MailBody = Get-Content -Path $Log | Out-String

        ## If an smtp password is configured, get the username and password together for authentication.
        ## If an smtp password is not provided then send the e-mail without authentication and obviously no SSL.
        If ($SmtpPwd)
        {
            $SmtpPwdEncrypt = Get-Content $SmtpPwd | ConvertTo-SecureString
            $SmtpCreds = New-Object System.Management.Automation.PSCredential -ArgumentList ($SmtpUser, $SmtpPwdEncrypt)

            ## If -ssl switch is used, send the email with SSL.
            ## If it isn't then don't use SSL, but still authenticate with the credentials.
            If ($UseSsl)
            {
                Send-MailMessage -To $MailTo -From $MailFrom -Subject $MailSubject -Body $MailBody -SmtpServer $SmtpServer -Port $SmtpPort -UseSsl -Credential $SmtpCreds
            }

            else {
                Send-MailMessage -To $MailTo -From $MailFrom -Subject $MailSubject -Body $MailBody -SmtpServer $SmtpServer -Port $SmtpPort -Credential $SmtpCreds
            }
        }

        else {
            Send-MailMessage -To $MailTo -From $MailFrom -Subject $MailSubject -Body $MailBody -SmtpServer $SmtpServer -Port $SmtpPort
        }
    }
}

## End