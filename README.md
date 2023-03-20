# Log Manager Utility

Flexible clean up and backup of log files.

For full change log and more information, [visit my site.](https://gal.vin/utils/log-manager-utility/)

Log Manager Utility is available from:

* [GitHub](https://github.com/Digressive/Log-Manager)
* [The Microsoft PowerShell Gallery](https://www.powershellgallery.com/packages/Log-Manager)

Please consider supporting my work:

* Sign up using [Patreon](https://www.patreon.com/mikegalvin).
* Support with a one-time donation using [PayPal](https://www.paypal.me/digressive).

Please report issues on Github via the issues tab.

-Mike

## Features and Requirements

* The utility will delete files and folders older than X days.
* It can also backup files and folders older than X days to another location.
* It can also compress backups as a zip file.
* The utility requires at least PowerShell 5.0
* This utility has been tested on Windows 11, Windows 10, Windows Server 2022, Windows Server 2019, Windows Server 2016 and Windows Server 2012 R2.

## Generating A Password File For SMTP Authentication

The password used for SMTP server authentication must be in an encrypted text file. To generate the password file, run the following command in PowerShell on the computer and logged in with the user that will be running the utility. When you run the command, you will be prompted for a username and password. Enter the username and password you want to use to authenticate to your SMTP server.

Please note: This is only required if you need to authenticate to the SMTP server when send the log via e-mail.

``` powershell
$creds = Get-Credential
$creds.Password | ConvertFrom-SecureString | Set-Content c:\scripts\ps-script-pwd.txt
```

After running the commands, you will have a text file containing the encrypted password. When configuring the -Pwd switch enter the path and file name of this file.

## Configuration

Here’s a list of all the command line switches and example configurations.

| Command Line Switch | Description | Example |
| ------------------- | ----------- | ------- |
| -LogsPath | The path that contains the logs that the utility should process. | [path\] |
| -LogKeep | Use this option to specify how long to keep logs for. Logs older than the number of days specified will be deleted. | [number] |
| -BackupTo | The path the logs should be backed up to. A folder will be created inside this location. If this option is not used, backup will not be performed. | [path\] |
| -BacKeep | Use this option to specify how long to keep the backups. Backups older than the number of days specified will be deleted. | [number] |
| -Wd | Specify a 'working directory' for the creation of the zip file. | [path\] |
| -Compress | This option will create a zip file of the log files. | N/A |
| -Sz | Configure the utility to use 7-Zip to compress the backups. 7-Zip must be installed in the default location ```$env:ProgramFiles``` if it is not found, Windows compression will be used. | N/A |
| -ZipName | Use this to name the zip file as you wish - the time and date will be appended to this name. | "'IIS Logs'" |
| -L | The path to output the log file to. | [path\] |
| -LogRotate | Remove logs produced by the utility older than X days | [number] |
| -NoBanner | Use this option to hide the ASCII art title in the console. | N/A |
| -Help | Display usage information. No arguments also displays help. | N/A |
| -Subject | Specify a subject line. If you leave this blank the default subject will be used | "'[Server: Notification]'" |
| -SendTo | The e-mail address the log should be sent to. For multiple address, separate with a comma. | [example@contoso.com] |
| -From | The e-mail address the log should be sent from. | [example@contoso.com] |
| -Smtp | The DNS name or IP address of the SMTP server. | [smtp server address] |
| -Port | The Port that should be used for the SMTP server. If none is specified then the default of 25 will be used. | [port number] |
| -User | The user account to authenticate to the SMTP server. | [example@contoso.com] |
| -Pwd | The txt file containing the encrypted password for SMTP authentication. | [path\ps-script-pwd.txt] |
| -UseSsl | Configures the utility to connect to the SMTP server using SSL. | N/A |

## Example

``` txt
[path\]Log-Manager.ps1 -LogsPath [path\] -LogKeep [number] -BackupTo [path\]
```

This will backup and remove logs in the path specified older than X days.
