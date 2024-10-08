﻿<#PSScriptInfo

.VERSION 22.06.01

.GUID 109eb5a2-1dd4-4def-9b9e-1d7413c8697f

.AUTHOR Mike Galvin Contact: digressive@outlook.com

.COMPANYNAME Mike Galvin

.COPYRIGHT (C) Mike Galvin. All rights reserved.

.TAGS Log Manager Clean up Backup Zip History MDT Microsoft Deployment Toolkit IIS Internet Information Services

.LICENSEURI https://github.com/Digressive/Log-Manager?tab=MIT-1-ov-file

.PROJECTURI https://gal.vin/utils/log-manager-utility/

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
    Delete files and folders older than X days, or backup files and folders older than X days to another location and then remove files.
    Run with -help or no arguments for usage.
#>

## Set up command line switches.
[CmdletBinding()]
Param(
    [alias("LogsPath")]
    $SourceUsr,
    [alias("LogKeep")]
    $LogHistory,
    [alias("BackupTo")]
    $BackupUsr,
    [alias("BacKeep")]
    $BacHistory,
    [alias("Wd")]
    $WorkDirUsr,
    [alias("ZipName")]
    $ZName,
    [alias("L")]
    $LogPathUsr,
    [alias("LogRotate")]
    $LogManOwnHistory,
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
    [switch]$Help,
    [switch]$NoBanner)

If ($NoBanner -eq $False)
{
    Write-Host -ForegroundColor Yellow -BackgroundColor Black -Object "
         __    _____  ___    __  __    __    _  _    __    ___  ____  ____     
        (  )  (  _  )/ __)  (  \/  )  /__\  ( \( )  /__\  / __)( ___)(  _ \    
         )(__  )(_)(( (_-.   )    (  /(__)\  )  (  /(__)\( (_-. )__)  )   /    
        (____)(_____)\___/  (_/\/\_)(__)(__)(_)\_)(__)(__)\___/(____)(_)\_)    
         __  __  ____  ____  __    ____  ____  _  _                            
        (  )(  )(_  _)(_  _)(  )  (_  _)(_  _)( \/ )       Mike Galvin         
         )(__)(   )(   _)(_  )(__  _)(_   )(   \  /      https://gal.vin       
        (______) (__) (____)(____)(____) (__)  (__)                            
                                                        Version 22.06.01       
                                                       See -help for usage     
                                                                               
                    Donate: https://www.paypal.me/digressive                   
"
}

If ($PSBoundParameters.Values.Count -eq 0 -or $Help)
{
    Write-Host -Object "PLEASE NOTE! This tool can be destructive! Please test it on non critical files first!
Usage:
    From a terminal run: [path\]Log-Manager.ps1 -LogsPath [path\] -LogKeep [number] -BackupTo [path\]
    This will backup and remove logs in the path specified older than X days.

    Use -BacKeep [number] option to specify how long to keep the backups.
    Use -Compress to create a zip file of the logs that are being backed up.
    Use -Sz to use 7-Zip to create a zip instead of Windows compression.
    7-Zip must be installed in the default location, if it is not found, Windows compression will be used.

    Use -Wd [path\] to specify a 'working directory' for the creation of the zip file.
    Use -ZipName [name] to name the zip file as you wish - the time and date will be appended to this name.
    If this left blank a default name of logs-HOSTNAME-date-time.zip will be used.

    To output a log: -L [path\].
    To remove logs produced by the utility older than X days: -LogRotate [number].
    Run with no ASCII banner: -NoBanner

    To use the 'email log' function:
    Specify the subject line with -Subject ""'[subject line]'"" If you leave this blank a default subject will be used
    Make sure to encapsulate it with double & single quotes as per the example for Powershell to read it correctly.

    Specify the 'to' address with -SendTo [example@contoso.com]
    For multiple address, separate with a comma.

    Specify the 'from' address with -From [example@contoso.com]
    Specify the SMTP server with -Smtp [smtp server name]

    Specify the port to use with the SMTP server with -Port [port number].
    If none is specified then the default of 25 will be used.

    Specify the user to access SMTP with -User [example@contoso.com]
    Specify the password file to use with -Pwd [path\]ps-script-pwd.txt.
    Use SSL for SMTP server connection with -UseSsl.

    To generate an encrypted password file run the following commands
    on the computer and the user that will run the script:
"
    Write-Host -Object '    $creds = Get-Credential
    $creds.Password | ConvertFrom-SecureString | Set-Content [path\]ps-script-pwd.txt'
}

else {
    ## If logging is configured, start logging.
    ## If the log file already exists, clear it.
    If ($LogPathUsr)
    {
        ## Clean User entered string
        $LogPath = $LogPathUsr.trimend('\')

        ## Make sure the log directory exists.
        If ((Test-Path -Path $LogPath) -eq $False)
        {
            New-Item $LogPath -ItemType Directory -Force | Out-Null
        }

        $LogFile = ("Log-Man_{0:yyyy-MM-dd_HH-mm-ss}.log" -f (Get-Date))
        $Log = "$LogPath\$LogFile"

        If (Test-Path -Path $Log)
        {
            Clear-Content -Path $Log
        }
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
            If ($LogPathUsr)
            {
                Add-Content -Path $Log -Encoding ASCII -Value "$(Get-DateFormat) [INFO] $Evt"
            }
            
            Write-Host -Object "$(Get-DateFormat) [INFO] $Evt"
        }

        If ($Type -eq "Succ")
        {
            If ($LogPathUsr)
            {
                Add-Content -Path $Log -Encoding ASCII -Value "$(Get-DateFormat) [SUCCESS] $Evt"
            }

            Write-Host -ForegroundColor Green -Object "$(Get-DateFormat) [SUCCESS] $Evt"
        }

        If ($Type -eq "Err")
        {
            If ($LogPathUsr)
            {
                Add-Content -Path $Log -Encoding ASCII -Value "$(Get-DateFormat) [ERROR] $Evt"
            }

            Write-Host -ForegroundColor Red -BackgroundColor Black -Object "$(Get-DateFormat) [ERROR] $Evt"
        }

        If ($Type -eq "Conf")
        {
            If ($LogPathUsr)
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
            catch {
                $_.Exception.Message | Write-Log -Type Err -Evt $_
            }

            ## If a working directory is configured by the user, remove all previous backup folders, including
            ## ones from previous versions of this script.
            If ($WorkDir -ne $Backup)
            {
                try {
                    Get-ChildItem -Path $Backup -Filter "$ZName-*-*-***-*-*" -Directory | Remove-Item -Recurse -Force
                }
                catch {
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
                catch {
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
                    catch {
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
                catch {
                    $_.Exception.Message | Write-Log -Type Err -Evt $_
                }

                ## If a working directory is configured by the user, remove all previous compressed backups,
                ## including ones from previous versions of this script.
                If ($WorkDir -ne $Backup)
                {
                    try {
                        Remove-Item "$Backup\$ZName-*-*-***-*-*.zip" -Force
                    }
                    catch {
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
                catch {
                    $_.Exception.Message | Write-Log -Type Err -Evt $_
                }

                ## If a working directory is configured by the user, remove previous compressed backups older
                ## than the configured number of days, including ones from previous versions of this script.
                If ($WorkDir -ne $Backup)
                {
                    try {
                        Get-ChildItem -Path "$Backup\$ZName-*-*-***-*-*.zip" | Where-Object CreationTime -lt (Get-Date).AddDays(-$BacHistory) | Remove-Item -Force
                    }
                    catch {
                        $_.Exception.Message | Write-Log -Type Err -Evt $_
                    }
                }

                Write-Log -Type Info -Evt "Removing compressed backups older than: $BacHistory days"
            }

            ## If the -compress switch and the -Sz switch IS configured, test for 7zip being installed.
            ## If it is, compress the backup folder, if it is not use Windows compression.
            If ($Sz -eq $True)
            {
                If (Test-Path -Path "$env:programfiles\7-Zip\7z.exe")
                {
                    Write-Log -Type Info -Evt "Compressing using 7-Zip compression"

                    try {
                        & "$env:programfiles\7-Zip\7z.exe" -bso0 a -tzip ("$WorkDir\$ZName-{0:yyyy-MM-dd_HH-mm-ss}.zip" -f (Get-Date)) "$WorkDir\$ZName\*"
                    }
                    catch {
                        $_.Exception.Message | Write-Log -Type Err -Evt $_
                    }
                }

                else {
                    Write-Log -Type Info -Evt "Compressing using Windows compression"
                    Add-Type -AssemblyName "system.io.compression.filesystem"
                    try {
                        [io.compression.zipfile]::CreateFromDirectory("$WorkDir\$ZName", ("$WorkDir\$ZName-{0:yyyy-MM-dd_HH-mm-ss}.zip" -f (Get-Date)))
                    }
                    catch {
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
            catch {
                $_.Exception.Message | Write-Log -Type Err -Evt $_
            }

            ## If a working directory has been configured by the user, move the compressed
            ## backup to the backup location and rename to include the date.
            If ($WorkDir -ne $Backup)
            {
                try {
                    Get-ChildItem -Path $WorkDir -Filter "$ZName-*-*-*-*-*.zip" | Move-Item -Destination $Backup
                }
                catch {
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
            catch {
                $_.Exception.Message | Write-Log -Type Err -Evt $_
            }

            If ($WorkDir -ne $Backup)
            {
                try {
                    Get-ChildItem -Path $WorkDir -Filter "$ZName-*-*-***-*-*" -Directory | Move-Item -Destination ("$Backup\$ZName-{0:yyyy-MM-dd_HH-mm-ss}" -f (Get-Date))
                }
                catch {
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

    If ($Null -eq $SourceUsr)
    {
        Write-Log -Type Err -Evt "You must specify -LogsPath."
        Exit
    }

    else {
        ## Clean User entered string
        $Source = $SourceUsr.trimend('\')

        If ($Null -eq $BackupUsr -And $BacHistory)
        {
            Write-Log -Type Err -Evt "You must specify -BackupTo to use -BacKeep."
            Exit
        }

        If ($Null -eq $BackupUsr -And $WorkDirUsr)
        {
            Write-Log -Type Err -Evt "You must specify -BackupTo to use -Wd."
            Exit
        }

        If ($Compress -eq $false -And $Null -ne $ZName)
        {
            Write-Log -Type Err -Evt "You must specify -Compress to use -ZipName."
            Exit
        }

        If ($Compress -eq $false -And $Sz -eq $true)
        {
            Write-Log -Type Err -Evt "You must specify -Compress to use -Sz."
            Exit
        }

        If ($Compress -eq $true -And $Null -eq $BackupUsr)
        {
            Write-Log -Type Err -Evt "You must specify -BackupTo to use -Compress."
            Exit
        }

        ## Clean User entered string
        If ($BackupUsr)
        {
            $Backup = $BackupUsr.trimend('\')
        }

        If ($WorkDirUsr)
        {
            $WorkDir = $WorkDirUsr.trimend('\')
        }

        If ($Null -eq $LogPathUsr -And $SmtpServer)
        {
            Write-Log -Type Err -Evt "You must specify -L [path\] to use the email log function."
            Exit
        }
    }

    ## getting Windows Version info
    $OSVMaj = [environment]::OSVersion.Version | Select-Object -expand major
    $OSVMin = [environment]::OSVersion.Version | Select-Object -expand minor
    $OSVBui = [environment]::OSVersion.Version | Select-Object -expand build
    $OSV = "$OSVMaj" + "." + "$OSVMin" + "." + "$OSVBui"

    ##
    ## Display the current config and log if configured.
    ##
    Write-Log -Type Conf -Evt "************ Running with the following config *************."
    Write-Log -Type Conf -Evt "Utility Version:.......22.06.01"
    Write-Log -Type Conf -Evt "Hostname:..............$Env:ComputerName."
    Write-Log -Type Conf -Evt "Windows Version:.......$OSV."

    If ($SourceUsr)
    {
        Write-Log -Type Conf -Evt "Path to process:.......$SourceUsr."
    }

    If ($Null -ne $LogHistory)
    {
        Write-Log -Type Conf -Evt "Logs to keep:..........$LogHistory days"
    }

    If ($BackupUsr)
    {
        Write-Log -Type Conf -Evt "Backup directory:......$BackupUsr."
    }

    If ($WorkDirUsr)
    {
        Write-Log -Type Conf -Evt "Working directory:.....$WorkDirUsr."
    }

    If ($Null -ne $BacHistory)
    {
        Write-Log -Type Conf -Evt "Backups to keep:.......$BacHistory days"
    }

    If ($ZName)
    {
        Write-Log -Type Conf -Evt "Zip file name:.........$ZName + date and time."
    }

    If ($Compress)
    {
        Write-Log -Type Conf -Evt "-Compress switch is:...$Compress."
    }

    If ($Sz)
    {
        Write-Log -Type Conf -Evt "-Sz switch is:.........$Sz."
    }

    If ($LogPathUsr)
    {
        Write-Log -Type Conf -Evt "Log directory:.........$LogPath."
    }

    If ($Null -ne $LogManOwnHistory)
    {
        Write-Log -Type Conf -Evt "Logs to keep:..........$LogManOwnHistory days."
    }

    If ($MailTo)
    {
        Write-Log -Type Conf -Evt "E-mail log to:.........$MailTo."
    }

    If ($MailFrom)
    {
        Write-Log -Type Conf -Evt "E-mail log from:.......$MailFrom."
    }

    If ($MailSubject)
    {
        Write-Log -Type Conf -Evt "E-mail subject:........$MailSubject."
    }

    If ($SmtpServer)
    {
        Write-Log -Type Conf -Evt "SMTP server:...........$SmtpServer."
    }

    If ($SmtpPort)
    {
        Write-Log -Type Conf -Evt "SMTP Port:.............$SmtpPort."
    }

    If ($SmtpUser)
    {
        Write-Log -Type Conf -Evt "SMTP user:.............$SmtpUser."
    }

    If ($SmtpPwd)
    {
        Write-Log -Type Conf -Evt "SMTP pwd file:.........$SmtpPwd."
    }

    If ($SmtpServer)
    {
        Write-Log -Type Conf -Evt "-UseSSL switch is:.....$UseSsl."
    }
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
        If ($BackupUsr)
        {
            ## Make sure the directory exists.
            If ((Test-Path -Path $Backup) -eq $False)
            {
                New-Item $Backup -ItemType Directory -Force | Out-Null
            }

            If ($Null -eq $WorkDirUsr)
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

        If ($LogPathUsr)
        {
            Get-ChildItem -Path $Source | Select-Object -ExpandProperty Name | Out-File -Append $Log -Encoding ASCII
        }

        If ($BackupUsr)
        {
            ## Test for the existence of a previous backup. If it exists, delete it.
            If (Test-Path -Path "$WorkDir\$ZName")
            {
                try {
                    Remove-Item "$WorkDir\$ZName" -Recurse -Force
                }
                catch {
                    $_.Exception.Message | Write-Log -Type Err -Evt $_
                }
            }

            Write-Log -Type Info -Evt "Attempting to move objects older than: $LogHistory days"

            try {
                New-Item -Path "$WorkDir\$ZName" -ItemType Directory | Out-Null
                Get-ChildItem -Path $Source | Where-Object CreationTime -lt (Get-Date).AddDays(-$LogHistory) | Copy-Item -Destination "$WorkDir\$ZName" -Recurse -Force
            }
            catch {
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

    If ($Null -ne $LogManOwnHistory)
    {
        ## Cleanup logs.
        Write-Log -Type Info -Evt "Deleting Log Manager logs older than: $LogManOwnHistory days"
        Get-ChildItem -Path "$LogPath\Log-Man_*" -File | Where-Object CreationTime -lt (Get-Date).AddDays(-$LogManOwnHistory) | Remove-Item -Recurse
    }

    ## This whole block is for e-mail, if it is configured.
    If ($SmtpServer)
    {
        If (Test-Path -Path $Log)
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

            ForEach ($MailAddress in $MailTo)
            {
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
                        Send-MailMessage -To $MailAddress -From $MailFrom -Subject $MailSubject -Body $MailBody -SmtpServer $SmtpServer -Port $SmtpPort -UseSsl -Credential $SmtpCreds
                    }

                    else {
                        Send-MailMessage -To $MailAddress -From $MailFrom -Subject $MailSubject -Body $MailBody -SmtpServer $SmtpServer -Port $SmtpPort -Credential $SmtpCreds
                    }
                }

                else {
                    Send-MailMessage -To $MailAddress -From $MailFrom -Subject $MailSubject -Body $MailBody -SmtpServer $SmtpServer -Port $SmtpPort
                }
            }
        }

        else {
            Write-Host -ForegroundColor Red -BackgroundColor Black -Object "There's no log file to email."
        }
    }
    ## End of Email block
}
## End