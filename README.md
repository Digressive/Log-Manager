# Log Manager Utility

Flexible clean up and backup of log files.

``` txt
 __    _____  ___    __  __    __    _  _    __    ___  ____  ____
(  )  (  _  )/ __)  (  \/  )  /__\  ( \( )  /__\  / __)( ___)(  _ \
 )(__  )(_)(( (_-.   )    (  /(__)\  )  (  /(__)\( (_-. )__)  )   /
(____)(_____)\___/  (_/\/\_)(__)(__)(_)\_)(__)(__)\___/(____)(_)\_)
 __  __  ____  ____  __    ____  ____  _  _
(  )(  )(_  _)(_  _)(  )  (_  _)(_  _)( \/ )
 )(__)(   )(   _)(_  )(__  _)(_   )(   \  /
(______) (__) (____)(____)(____) (__)  (__)

      Mike Galvin    https://gal.vin    Version 21.12.08
```

For full instructions and documentation, [visit my site.](https://gal.vin/posts/powershell-log-manager)

Please consider supporting my work:

* Sign up [using Patreon.](https://www.patreon.com/mikegalvin)
* Support with a one-time payment [using PayPal.](https://www.paypal.me/digressive)

Log Manager Utility can also be downloaded from:

* [The Microsoft PowerShell Gallery](https://www.powershellgallery.com/packages/Log-Manager)

Join the [Discord](http://discord.gg/5ZsnJ5k) or Tweet me if you have questions: [@mikegalvin_](https://twitter.com/mikegalvin_)

-Mike

## Features and Requirements

* The utility will delete files and folders older than X days.
* Can also backup files and folders older than X days to another location.
* Backup files and folders as a zip file.
* The utility requires at least PowerShell 5.0
* This utility has been tested on Windows 10, Windows Server 2019, Windows Server 2016 and Windows Server 2012 R2 (Datacenter and Core Installations).

### Generating A Password File

The password used for SMTP server authentication must be in an encrypted text file. To generate the password file, run the following command in PowerShell on the computer and logged in with the user that will be running the utility. When you run the command, you will be prompted for a username and password. Enter the username and password you want to use to authenticate to your SMTP server.

Please note: This is only required if you need to authenticate to the SMTP server when send the log via e-mail.

``` powershell
$creds = Get-Credential
$creds.Password | ConvertFrom-SecureString | Set-Content c:\scripts\ps-script-pwd.txt
```

After running the commands, you will have a text file containing the encrypted password. When configuring the -Pwd switch enter the path and file name of this file.

### Configuration

Here’s a list of all the command line switches and example configurations.

| Command Line Switch | Description | Example |
| ------------------- | ----------- | ------- |
| -LogsPath | The path that contains the logs that the utility should process. | ```C:\inetpub\logs\LogFiles\W3SVC*\*``` |
| -LogKeep | Instructs the utility to keep a specified number of days’ worth of logs. Logs older than the number of days specified will be deleted. | 30 |
| -BackupTo | The path the logs should be backed up to. A folder will be created inside this location. Do not add a trailing backslash. If this option is not used, backup will not be performed. | ```\\nas\archive``` |
| -BacKeep | Instructs the utility to keep a specified number of days’ worth of backups. Backups older than the number of days specified will be deleted. Only backup folders or zip files created by this utility will be removed. | 30 |
| -Wd | The path to the working directory to use for the backup before copying it to the final backup directory. Use a directory on local fast media to improve performance. | ```C:\temp``` |
| -Compress | This option will create a zip file of the log files. | N/A |
| -Sz | Configure the utility to use 7-Zip to compress the log files. 7-Zip must be installed in the default location ($env:ProgramFiles) if it is not found, Windows compression will be used as a fallback. | N/A |
| -ZipName | Enter the name of the zip file you wish to have. If the name includes a space, encapsulate with single quotes. The time and date will be appended to this name. If this option is not used, a default name of logs-HOSTNAME-date-time.zip will be used. | 'IIS Logs' |
| -NoBanner | Use this option to hide the ASCII art title in the console. | N/A |
| -L | The path to output the log file to. The file name will be Log-Man_YYYY-MM-dd_HH-mm-ss.log. Do not add a trailing \ backslash. | ```C:\scripts\logs``` |
| -Subject | The subject line for the e-mail log. Encapsulate with single or double quotes. If no subject is specified, the default of "Log Manager Utility Log" will be used. | 'Server: Notification' |
| -SendTo | The e-mail address the log should be sent to. | me@contoso.com |
| -From | The e-mail address the log should be sent from. | Log-Manager@contoso.com |
| -Smtp | The DNS name or IP address of the SMTP server. | smtp.live.com OR smtp.office365.com |
| -User | The user account to authenticate to the SMTP server. | example@contoso.com |
| -Pwd | The txt file containing the encrypted password for SMTP authentication. | ```C:\scripts\ps-script-pwd.txt``` |
| -UseSsl | Configures the utility to connect to the SMTP server using SSL. | N/A |

### Example

``` txt
Log-Manager.ps1 -LogsPath C:\inetpub\logs\LogFiles\W3SVC*\* -LogKeep 30 -BackupTo \\nas\archive -BacKeep 30 -Wd C:\temp -Compress -L C:\scripts\logs -Subject 'Server: Log Manager' -SendTo me@contoso.com -From Log-Manager@contoso.com -Smtp smtp.outlook.com -User me@contoso.com -Pwd c:\scripts\ps-script-pwd.txt -UseSsl
```

The above command will backup and remove IIS logs older than 30 days. It will create a zip folder using the ```C:\temp``` folder as a working directory and the file will be stored in ```\\nas\archive```. The log file will be output to ```C:\scripts\logs``` and sent via e-mail with a custom subject line.
