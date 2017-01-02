#! /bin/bash

echo 'Hello, daemons! Welcome to the cpix script!'
echo 'The script is now running...'

function main {
	echo "main function running..."

#	begin scripts

	aptf #apt-get update #
	toolbelt #install tools #
	noport #enables ufw
	lockdown #locks accounts #
	nopass #sets password policies
	sshfix #sshconfig #
	nomedia #gets rid of media files #
#	scruboff #get rid of software

#	end of scripts

	echo "Script is complete..."
	echo "Begin fishing for points...\n"
	cont
}


# function that pauses between steps
function cont {
	read -n1 -p "Press space to continue, AOK to quit" key
	if [ "$key" = "" ]; then
		echo "Moving forward..."
	else
		echo "Quitting script..."
		exit 1
	fi
}

#apt update
function aptf {
	echo ""
	echo "Check your sources! Software & Updates\n"

	#offline solution
	cp ./mysources.list /etc/apt/sources.list

	#online solution
#	curl https://repogen.simplylinux.ch/txt/trusty/sources_61c3eb1fcff54480d3fafbec45abfe85c2a4b1a8.txt | tee /etc/apt/sources.list

	cont
	apt-get -y update
	apt-get -y upgrade
#	apt-get -y install --reinstall coreutils
	echo "Finished updating"
}

#install tools to use for misc purposes
function toolbelt {
	echo ""
	echo 'installing utilities...'
	apt-get -y install \
	vim \
	ufw \
	gufw \
	firefox \
	clamav \
	netstat \
	nmap \
	libpam-cracklib \
	lsof \
	locate \
	chkrootkit \
	openssh-server
	echo "Finished installs"
	updatedb
	echo "Updated database"
	cont
}



#blocks ports and traffic
function noport {
	echo ""
	echo "Enabling Uncomplicated Firewall..."
	ufw enable
	cont

	echo "preventing ddos attacks"
	sysctl -w net.ipv4.tcp_syncookies=1
	cont

	echo "Verify rules..."
	ufw status
	cont
	echo "Finished managing rules"
}


#locks root and home
function lockdown {
	echo ""
	echo "Locking root user"
	passwd -l root
	echo "root locked"
	hahahome='HOME'
	chmod 0750 ${!hahahome}
	echo "home directory locked"
	cont
}


#manages password policies
#this should be its own script
function nopass {
	echo ""
	echo "Changing password policies requires manual interaction\n"
	echo "Please open Mr. Silva's checklist for instructions\n"
	echo "Changing password policies requires manual interaction"
	echo "Please open Mr. Silva's checklist for instructions"

	#run cracklib

	#login.defs
	echo "Making a backup login.defs file..."
	cp /etc/login.defs /etc/login.defs.backup
	chmod a-w /etc/login.defs.backup
	cont

	echo "Copying local login.defs file..."
	cp ./my_login.defs /etc/login.defs

	# This is expiremental, I do not trust this feature yet.
	#XXX This will probably screw up comments
#	sed -i 's/PASS_MIN_DAYS.*/PASS_MIN_DAYS 2/g' /etc/login.defs
#	sed -i 's/PASS_MAX_DAYS.*/PASS_MAX_DAYS 60/g' /etc/login.defs
#	sed -i 's/LOGIN_RETRIES.*/LOGIN_RETRIES 3/g' /etc/login.defs

	#common-password
	echo "Making a backup config file..."
	cp /etc/pam.d/common-password /etc/pam.d/common-password.backup
	chmod a-w /etc/pam.d/common-password.backup
	cont

	echo "Copying local common-password file..."
	cp ./my_common-password /etc/pam.d/common-password

	echo 'Password policies configured'
	# done configuring

	# will change pass age for users aready created
	echo "Applying to all users..."
	for i in $(awk -F':' '/\/home.*sh/ { print $1 }' /etc/passwd); do chage -m 3 -M 60 -W 7 $i; done
	echo "Password Policies finished."
	cont
}


#easy point here
function sshfix {
	echo ''
	echo 'Turn off root login settings for ssh'
	echo 'This must be performed manually'
	echo "Making a backup config file..."
	cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup
	chmod a-w /etc/ssh/sshd_config.backup
	cont

	#permitrootlogin
	cp ./sshdconfig /etc/ssh/sshd_config
	cont

	#enables/disables ssh
	service ssh restart
	read -n1 -r -p "Press 1 to turn off ssh, space to continue..." key
	if [ "$key" = '1' ]; then
		service ssh stop
	fi

	echo 'Finished ssh config editing'
	cont
}

#TODO
#finds and deletes media files
function nomedia {
	echo "Deleting media..."
	find / -name '*.mp3' -type f -delete
	find / -name '*.mov' -type f -delete
	find / -name '*.mp4' -type f -delete
	find / -name '*.avi' -type f -delete
	find / -name '*.mpg' -type f -delete
	find / -name '*.mpeg' -type f -delete
	find / -name '*.flac' -type f -delete
	find / -name '*.m4a' -type f -delete
	find / -name '*.flv' -type f -delete
	find / -name '*.ogg' -type f -delete
	find /home -name '*.gif' -type f -delete
	find /home -name '*.png' -type f -delete
	find /home -name '*.jpg' -type f -delete
	find /home -name '*.jpeg' -type f -delete
	echo "Media deleted"
	cont
}


#TODO
function scruboff {
	echo ''
	echo 'check for unwanted apps manually'
	chkrootkit
	freshclam
	clamscan -i -r --remove=yes /
	service --status-all | less
	sudo dpkg --get --selections | less
	netstat -tulpn | grep -i LISTEN | less
	cat /etc/rc.local | less
	crontab -e | less
	echo 'Please remove any unwanted apps NOW'
	read -n1 -r -p "Press space to continue..." key
	if [ "$key" = '' ]; then
		apt-get --purge autoremove
	else
		echo 'Exiting script...'
		exit 1
	fi
	echo 'Finished uninstalling'
}

#actually running the script
unalias -a #Get rid of aliases
echo "unalias -a" >> ~/.bashrc
echo "unalias -a" >> /root/.bashrc
if [ "$(id -u)" != "0" ]; then
	echo "Please run as root"
	exit
else
	main
fi
