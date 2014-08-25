#!/bin/bash

# A VirtualHost manager for Apache 2.4.7, tested on Ubuntu 14.04 LTS

# by unnikked
#	- http://unnikked.tk (italian website)
#	- http://en.unnikked.tk (english website)

if [ "$(id -u)" != 0 ]; then
	echo "You must be root or use sudo"
	exit 1
fi

if ! which apache2 > /dev/null; then
	echo -e "You must install apache webserver first\n	sudo apt-get install apache2"
	exit 1
fi

function show_help() {
	cat << EOF
Usage: ${0##*/} -vh [-a ACTION ] [-e EMAIL] [-w DOMAIN_NAME] [-n VHOST_NAME] [-d DIR_NAME] 
	
	-a			create, delete or list
	-e			webmaster email
	-w			domain name (eg example.com)
	-n			name of the virtual host (if not specified it uses
				DOMAIN_NAME)
	-d			directory name of the root directory (if not specified it uses
				VHOST_NAME)
	-v			verbose
	-h			this help		
EOF
}

aFlag=false
action=""
email="webmaster@localhost"
wFlag=false
domainname=""
vhostname=""
dirname=""
vFlag=false
verbose=0

OPTIND=1

sitesEnabled="/etc/apache2/sites-enabled/"
sitesAvailable="/etc/apache2/sites-available/"
apacheWWW="/var/www/"

while getopts "a:e:w:n:d:vh" opt; do
	case "$opt" in
		v)	verbose=$((verbose+1))
			vFlag=true
			;;
		e)	email=$OPTARG
			;;
		a)	action=$OPTARG
			aFlag=true
			;;
		w)	domainname=$OPTARG
			wFlag=true
			;;
		n)	vhostname=$OPTARG
			;;
		d)	dirname=$OPTARG
			;;
		h) 	show_help
			exit 0
			;;
		'?')
#			show_help >&2
			exit 1
			;;
	esac
done

shift "$((OPTIND-1))" # Shift off the options and optional --.

if ! $aFlag; then # -a is mandatory
	echo "You must specify an action: create or delete"
	exit 1
fi

if [ $action == "list" ]; then
	ls $sitesAvailable
	exit 0
fi

if ! $wFlag; then # -w is mandatory
	echo "You must atleast provide a domain name"
	exit 1
fi

# if no -n is provided then it will be set the same as domainname
if [ -z "$vhostname" ]; then 
	vhostname="$domainname"
fi

# if no -d is provided then it will be set the same as vhostname
if [ -z "$dirname" ]; then
	dirname="$vhostname"
fi

vHostTemplate="$(echo "
<VirtualHost *:80>
	ServerAdmin $email 
	ServerAlias $domainname www.$domainname
	ServerName $domainname
	DocumentRoot /var/www/$dirname
	<Directory />
		Options FollowSymLinks
		AllowOverride None
	</Directory>
	<Directory /var/www/$dirname>
		Options Indexes FollowSymLinks MultiViews
		AllowOverride all
		Order allow,deny
		allow from all
	</Directory>

	ScriptAlias /cgi-bin/ /usr/lib/cgi-bin/
	<Directory "/usr/lib/cgi-bin">
		AllowOverride None
		Options +ExecCGI -MultiViews +SymLinksIfOwnerMatch
		Order allow,deny
		Allow from all
	</Directory>

	ErrorLog ${APACHE_LOG_DIR}/error.log

	# Possible values include: debug, info, notice, warn, error, crit,
	# alert, emerg.
	LogLevel warn

	CustomLog ${APACHE_LOG_DIR}/access.log combined
</VirtualHost>")"

function verbose() {
	if $vFlag; then
		echo "$1"
	fi
	return 0
}

if [ $action == "create" ]; then
	# checks if domain already exists
	if [ -e $sitesAvailable$vhostname ]; then
		echo -e "This domain already exists."
		exit 1;
	fi
	
	# checks if the folder already exists
	if [ -d $apacheWWW$dirname ]; then
		echo "Directory already exists!"
		exit 1;
	fi
	
	# creates the folder
	if ! mkdir -p $apacheWWW$dirname > /dev/null; then
		echo "An error occurred while creating "$apacheWWW$dirname""
		exit 1
	else 
		echo "Folder "$apacheWWW$dirname" created"
	fi
	
	# sets www-data permission
	if chown -R www-data:www-data $apacheWWW$dirname > /dev/null; then
		verbose "Folder permission changed"
	else 
		echo "An error occurred while changing permission to "$dirname""
		exit 1
	fi
	
	# creates VirtualHost file
	if echo "$vHostTemplate" > $sitesAvailable$vhostname.conf; then
		verbose "VirtualHost created"
	else
		echo "An error occurred! Could not write to $sitesAvailable$vhostname"
		exit 1
	fi
	
	# enables virtual host
	if a2ensite "$vhostname.conf" > /dev/null; then
		verbose "Site "$domainname" enabled."
	else
		echo "An error occurred while enabling "$domainname""
		exit 1
	fi
	
	# reloads apache config
	if service apache2 reload > /dev/null; then 
		verbose "Apache config reloaded"
	else
		echo "An error occurred while reloading apache"
		exit 1
	fi
	exit 0
fi

if [ "$action" == "delete" ]; then
	
	# checks if the domain does not exists
	if ! [ -e $sitesAvailable$vhostname.conf ]; then
		echo -e "This domain does not exists."
		exit 1;
	fi
	
	# checks if the folder does not exists
	if ! [ -d $apacheWWW$dirname ]; then
		echo "Directory does not exists!"
		exit 1;
	fi
	
	# disable virtual host
	if a2dissite -q "$vhostname.conf" > /dev/null; then
		verbose "Domain "$domainname" disabled"
	else
		echo "An error occurred while disabling "$domainname""
		exit 1
	fi
	
	# deletes virtual host file
	if rm $sitesAvailable$vhostname.conf > /dev/null; then
		verbose "VirtualHost "$vhostname" deleted."
	else
		echo "An error occurred while deleting directory "$dirname""
		exit 1
	fi
	
	# deletes the directory
	if rm -rf $apacheWWW$dirname > /dev/null; then
		verbose "Directory "$dirname" deleted."
	else
		echo "An error occurred while deleting directory "$dirname""
		exit 1
	fi
	
	# reloads apache config
	if service apache2 reload > /dev/null; then 
		verbose "Apache config reloaded"
	else
		echo "An error occurred while reloading apache"
		exit 1
	fi
	exit 0
fi

echo "Unknow action!"
exit 1
