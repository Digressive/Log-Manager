# Log Manager

PowerShell based log file cleanup/archiver

Please consider donating to support my work:

* You can support me on a monthly basis [using Patreon.](https://www.patreon.com/mikegalvin)
* You can support me with a one-time payment [using PayPal](https://www.paypal.me/digressive) or by [using Kofi.](https://ko-fi.com/mikegalvin)

Log Manager can also be downloaded from:

* For full instructions and documentation, [visit my blog post](https://gal.vin/2017/06/13/powershell-log-manager)
* [The Microsoft TechNet Gallery](https://gallery.technet.microsoft.com/scriptcenter/Log-Manager-PowerShell-c558219c?redir=0)
* [The PowerShell Gallery](https://www.powershellgallery.com/packages/Log-Manager)

-Mike

Tweet me if you have questions: [@mikegalvin_](https://twitter.com/mikegalvin_)

## Features and Requirements

This utility can be configured to do the following:

* Delete files and folder trees older than X days.
* Move files and folder trees to another location.
* Archive files and folder trees as a ZIP file.

### A Quick Self-Aware Note

I’m totally aware that my script is designed to manage log files and yet it will also generate a log file, if required. I prefer to get a notification when a server runs a script, so that’s why all of my scripts have this option. Some of my scripts generate a log file that gets overwritten each time they run, so they shouldn’t build up over time, but for everything else this script should help.

### Generating A Password File

The password used for SMTP server authentication must be in an encrypted text file. To generate the password file, run the following command in PowerShell, on the computer that is going to run the script and logged in with the user that will be running the script. When you run the command you will be prompted for a username and password. Enter the username and password you want to use to authenticate to your SMTP server.

Please note: This is only required if you need to authenticate to the SMTP server when send the log via e-mail.

``` powershell
$creds = Get-Credential
$creds.Password | ConvertFrom-SecureString | Set-Content c:\scripts\ps-script-pwd.txt
```

After running the commands, you will have a text file containing the encrypted password. When configuring the -Pwd switch enter the path and file name of this file.

### Configuration

Here’s a list of all the command line switches and example configurations.

``` txt
-Path
```

The root path that contains the files and or folders that the script should operate on.

``` txt
-Days
```

The number of days from the current date that files created during should be untouched.

``` txt
-Backup
```

The location that the files and folders should be backed up to.
If you do not set this, a back up will not be performed.

``` txt
-WorkDir
```

The path of the working directory used for ZIP file creation. This should be local for best performance.
If you do not set this, the files will not be zipped.

``` txt
-L
```

The path to output the log file to.
The file name will be Log-Manager.log.

``` txt
-Subject
```

The email subject that the email should have. Encapulate with single or double quotes.

``` txt
-SendTo
```

The e-mail address the log should be sent to.

``` txt
-From
```

The from address the log should be sent from.

``` txt
-Smtp
```

The DNS name or IP address of the SMTP server.

``` txt
-User
```

The user account to connect to the SMTP server.

``` txt
-Pwd
```

The password for the user account.

``` txt
-UseSsl
```

Connect to the SMTP server using SSL.

### Example

``` txt
Log-Manager.ps1 -Path C:\inetpub\logs\LogFiles\W3SVC*\* -Days 30 -Backup \\nas\archive -WorkDir C:\scripts -L C:\scripts\logs -Subject 'Server: Logs Cleanup' -SendTo me@contoso.com -From Log-Manager@contoso.com -Smtp exch01.contoso.com -User me@contoso.com -Pwd P@ssw0rd -UseSsl
```

With these settings, the script will archive IIS logs files older than 30 days as a ZIP file in \\nas\archive, using the C:\scripts folder as a working directory. The log file of the scritp will be output to C:\scripts\logs and e-mailed with a custom subject line, using an SSL connection.
