# VirtualHost manager for Apache 2.4.7

Since I test various opensource selfhosted apps on my virtual machine I decided to create a small script written in bash that helps me to configure initial settings.

I've tested it on Ubuntu 14.04 LTS, it should work also for earlier version and with different Apache versione, please let me know. 

I might update the script for backward and future compatibility. 

This release it is only a prototype.

## What does the script do?
This script basically lets you create, delete or list all available apache VirtualHost.

## Syntax

```
Usage: vhost-manager -vh [-a ACTION ] [-e EMAIL] [-w DOMAIN_NAME] [-n VHOST_NAME] [-d DIR_NAME] 
	
	-a			create, delete or list
	-e			webmaster email
	-w			domain name (eg example.com)
	-n			name of the virtual host (if not specified it uses
				DOMAIN_NAME)
	-d			directory name of the root directory (if not specified it uses
				VHOST_NAME)
	-v			verbose
	-h			this help		
```
