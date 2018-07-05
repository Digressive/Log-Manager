<#PSScriptInfo

.VERSION 1.7

.GUID 109eb5a2-1dd4-4def-9b9e-1d7413c8697f

.AUTHOR Mike Galvin twitter.com/digressive

.COMPANYNAME

.COPYRIGHT (C) Mike Galvin. All rights reserved.

.TAGS Log Manager Cleanup MDT Microsoft Deployment Toolkit IIS Internet Information Services

.LICENSEURI

.PROJECTURI https://gal.vin/2017/06/13/powershell-log-manager/

.ICONURI

.EXTERNALMODULEDEPENDENCIES 

.REQUIREDSCRIPTS

.EXTERNALSCRIPTDEPENDENCIES

.RELEASENOTES

#>

<#
    .SYNOPSIS
    The script can cleanup and optionally archive old logs files.
    
    .DESCRIPTION
    The script can cleanup and optionally archive old logs files.

    This script can:
    
    Delete files and folder trees older than X days.
    Move files and folder trees to another location, after X days.
    Archive files and folder tress as a ZIP file, after X days.

    Please note: to send a log file using ssl and an SMTP password you must generate an encrypted
    password file. The password file is unique to both the user and machine.
    
    The command is as follows:

    $creds = Get-Credential
    $creds.Password | ConvertFrom-SecureString | Set-Content c:\foo\ps-script-pwd.txt
   
    .PARAMETER Path
    The root path that contains the files and or folders that the script should operate on.

    .PARAMETER Days
    The number of days from the current date that files created during should be untouched.

    .PARAMETER Backup
    The location that the files and folders should be backed up to.
    If you do not set this, a back up will not be performed.

    .PARAMETER WorkDir
    The path of the working directory used for ZIP file creation. This should be local for best performance.
    If you do not set this, the files will not be zipped.
    
    .PARAMETER L
    The path to output the log file to.
    The file name will be Log-Manager-Log.log.

    .PARAMETER SendTo
    The e-mail address the log should be sent to.

    .PARAMETER From
    The from address the log should be sent from.

    .PARAMETER Smtp
    The DNS name or IP address of the SMTP server.

    .PARAMETER User
    The user account to connect to the SMTP server.

    .PARAMETER Pwd
    The password for the user account.

    .PARAMETER UseSsl
    Connect to the SMTP server using SSL.

    .EXAMPLE
    Log-Manager.ps1 -Path C:\inetpub\logs\LogFiles\W3SVC*\* -Days 30 -Backup \\nas\archive -WorkDir E:\scripts -L E:\scripts\log -SendTo me@contoso.com -From Log-Manager@contoso.com -Smtp exch01.contoso.com -User me@contoso.com -Pwd P@ssw0rd -UseSsl
    With these settings, the script will archive IIS logs files older than 30 days as a ZIP file in \\nas\archive, using the E:\scripts
    folder as a working directory. The log file of the scritp will be output to E:\scripts\log and emailed using an SSL connection.
#>

## Set up command line switches and what variables they map to
[CmdletBinding()]
Param(
    [parameter(Mandatory=$True)]
    [alias("Path")]
    $Source,
    [parameter(Mandatory=$True)]
    [alias("Days")]
    $Time,
    [alias("Backup")]
    $Dest,
    [alias("WorkDir")]
    $Zip,
    [alias("L")]
    $LogPath,
    [alias("SendTo")]
    $MailTo,
    [alias("From")]
    $MailFrom,
    [alias("Smtp")]
    $SmtpServer,
    [alias("User")]
    $SmtpUser,
    [alias("Pwd")]
    $SmtpPwd,
    [switch]$UseSsl)

## Count the number of files that are old enough to work on in the configured directory
$FileNo = Get-ChildItem $Source –Recurse | Where-Object CreationTime –lt (Get-Date).AddDays(-$Time) | Measure-Object

## If the number of the files to work on is zero, do nothing
If ($FileNo.count -ne 0)
{
    ## If logging is configured, start log
    If ($LogPath)
    {
        $LogFile = "Log-Manager-Log.log"
        $Log = "$LogPath\$LogFile"

        ## If the log file already exists, clear it
        $LogT = Test-Path -Path $Log

        If ($LogT)
        {
            Clear-Content -Path $Log
        }

        Add-Content -Path $Log -Value "****************************************"
        Add-Content -Path $Log -Value "$(Get-Date -Format G) Log started"
        Add-Content -Path $Log -Value " "
    }

    If ($LogPath)
    {
        Add-Content -Path $Log -Value "$(Get-Date -Format G) The following objects are older than: $Time days and will be processed:"
        Get-ChildItem $Source | Select Name,LastWriteTime | Out-File -Append $Log -Encoding ASCII
        Add-Content -Path $Log -Value " "
    }

    ## If the zip option was configured, copy the working files to a temp dir and create a zip file, then remove the temp dir and move the zip file
    If ($Zip)
    {
        Add-Type -AssemblyName "system.io.compression.filesystem"
        New-Item -Path $Zip\temp -ItemType Directory
        Get-ChildItem $Source | Where-Object CreationTime –lt (Get-Date).AddDays(-$Time) | Copy-Item -Destination $Zip\temp -Recurse -Force
        [io.compression.zipfile]::CreateFromDirectory("$Zip\temp", "$Zip\Logs-{0:yyyy-MM-dd-HH-mm}.zip" -f (Get-Date))
        Remove-Item $Zip\temp -Recurse
        Move-Item $Zip\Logs-*.zip $Dest
        Get-ChildItem $Source –Recurse | Where-Object CreationTime –lt (Get-Date).AddDays(-$Time) | Remove-Item -Recurse

        If ($LogPath)
        {
            Add-Content -Path $Log -Value "$(Get-Date -Format G) Zip file created and copied to: $Dest"
        }
    }

    ## If the backup directory was configured, copy the files to the backup dir
    If ($Dest)
    {
        Get-ChildItem $Source | Where-Object CreationTime –lt (Get-Date).AddDays(-$Time) | Copy-Item -Destination $Dest -Recurse -Force

        If ($LogPath)
        {
            Add-Content -Path $Log -Value "$(Get-Date -Format G) Contents of the backup location: $Dest"
            Get-ChildItem $Dest | Select Name,LastWriteTime | Out-File -Append $Log -Encoding ASCII
        }
    }

    ## If no backup options were configured, or after doing the previous operations, remove the old files
    Get-ChildItem $Source –Recurse | Where-Object CreationTime –lt (Get-Date).AddDays(-$Time) | Remove-Item -Recurse

    ## If log was configured stop the log
    If ($LogPath)
    {
        Add-Content -Path $Log -Value " "
        Add-Content -Path $Log -Value "$(Get-Date -Format G) Log finished"
        Add-Content -Path $Log -Value "****************************************"

        ## If email was configured, set the variables for the email subject and body
        If ($SmtpServer)
        {
            $MailSubject = "Log Manager Log"
            $MailBody = Get-Content -Path $Log | Out-String

            ## If an email password was configured, create a variable with the username and password
            If ($SmtpPwd)
            {
                $SmtpPwdEncrypt = Get-Content $SmtpPwd | ConvertTo-SecureString
                $SmtpCreds = New-Object System.Management.Automation.PSCredential -ArgumentList ($SmtpUser, $SmtpPwdEncrypt)

                ## If ssl was configured, send the email with ssl
                If ($UseSsl)
                {
                    Send-MailMessage -To $MailTo -From $MailFrom -Subject $MailSubject -Body $MailBody -SmtpServer $SmtpServer -UseSsl -Credential $SmtpCreds
                }

                ## If ssl wasn't configured, send the email without ssl
                Else
                {
                    Send-MailMessage -To $MailTo -From $MailFrom -Subject $MailSubject -Body $MailBody -SmtpServer $SmtpServer -Credential $SmtpCreds
                }
            }

            ## If an email username and password were not configured, send the email without authentication
            Else
            {
                Send-MailMessage -To $MailTo -From $MailFrom -Subject $MailSubject -Body $MailBody -SmtpServer $SmtpServer
            }
        }
    }
}

## End