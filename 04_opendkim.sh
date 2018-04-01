#!/bin/bash
# ------------------------------------------------------------------
# [Date: 28/07/2017]
# [Author: MarcelFox] 
# [email: contato@marcelfox.com]
#
#	Title: 'opendkim.sh'
#       The script configure the Opendkim for Debian 9 server,
#	but with a few modifications you'll be able to ran it 
#	on every Linux Distro. 
#
#	Does:
#		- Check previous configurations.
#		- Save backups of every configuration file before
#		  change it.
#		- Generate directories at '/etc/opendkim'.
#		- Generate new key for the given domain.
#		- Alerts for DNS and Postfix configurations.
#	
#	Don't:
#		- Does not configure your mail server.
#		- Does not check for integrity of the KeyFile,
#		  SingingTable files. It's important to check those.
#
#	Fixes, Contacts and Improvements are encouraged! =)
#
# ------------------------------------------------------------------


##
# Set selector variable as YYYYMMDD:
##

SELECTOR_VAR=$(date +%Y%m%d)



##
# Ask if it'll be needed to Download Opendkim packages:
##

echo
echo "Download and install OpenDKIM packages? (y/n):"

read var

if [ $var == "y" ] || [ $var == "Y" ]; then
    apt-get update
    apt-get install -y opendkim opendkim-tools
elif [ $var == "n" ] || [ $var == "N" ]; then
    echo
    echo "Skipping..."
    echo
else
    echo
    echo "Please inform only 'y' or 'n'!"
    echo
    exit
fi



##
# Check if the keys directory already exists:
##

if [ ! -d /etc/opendkim ]; then
    mkdir /etc/opendkim
else
    echo
    echo "It seems that an Opendkim configuration already exists. Continue? (y/n):"

    read var

    if [ $var == "y" ] || [ $var == "Y" ]; then
        echo "Ok!"
    elif [ $var == "n" ] || [ $var == "N" ]; then
        echo
	echo "Ok, I'm here if you need!"
	echo
	exit
    else
	echo
	echo "Please inform only 'y' or 'n'!"
	echo
	exit
    fi
fi


if [ -f /etc/opendkim.conf ]; then
    cp /etc/opendkim.conf /etc/opendkim.conf.saved.${SELECTOR_VAR}
    echo
    echo "I've saved the original conf file to '/etc/opendkim.conf.saved.${SELECTOR_VAR}'"
    echo
else
    echo
    echo "There's an issue with your Opendkim installation, check those and come back!"
    echo
    exit
fi



##
# Read the domain to generate the dkim:
##

echo
echo "Inform the domain, like 'example.com', in which you'll add the DKIM key:"

read DOMAIN_DKIM



##
# Checks the main configuration file:
##

grep -E 'KeyTable|SigningTable|ExternalIgnoreList|InternalHosts' /etc/opendkim.conf > /dev/null
#
# Stores the last command value, then continue:
#
LAST_CMD=$?

if [ $LAST_CMD == 1]; then

	echo "KeyTable           /etc/opendkim/KeyTable" >> /etc/opendkim.conf
	echo "SigningTable       /etc/opendkim/SigningTable" >> /etc/opendkim.conf
	echo "ExternalIgnoreList /etc/opendkim/TrustedHosts" >> /etc/opendkim.conf
	echo "InternalHosts      /etc/opendkim/TrustedHosts" >> /etc/opendkim.conf
fi

if [ $LAST_CMD == 0 ]; then
    echo
    echo "I found those non-default settings on '/etc/opendkim.conf':"
    grep -E 'KeyTable|SigningTable|ExternalIgnoreList|InternalHosts' /etc/opendkim.conf
    echo
    echo "Do you want to comment these lines? (y/n):"

    read var

    if [ $var == "y" ] || [ $var == "Y" ]; then
	sed -i.bak '/KeyTable/ s/^/#/g' /etc/opendkim.conf
	sed -i.bak '/SigningTable/ s/^/#/g' /etc/opendkim.conf
	sed -i.bak '/ExternalIgnoreList/ s/^/#/g' /etc/opendkim.conf
	sed -i.bak '/InternalHosts/ s/^/#/g' /etc/opendkim.conf
	
	echo "KeyTable           /etc/opendkim/KeyTable" >> /etc/opendkim.conf
	echo "SigningTable       /etc/opendkim/SigningTable" >> /etc/opendkim.conf
	echo "ExternalIgnoreList /etc/opendkim/TrustedHosts" >> /etc/opendkim.conf
	echo "InternalHosts      /etc/opendkim/TrustedHosts" >> /etc/opendkim.conf
	
    elif [ $var == "n" ] || [ $var == "N" ]; then	
	echo "Skipping..."
	echo "Be sure that your opendkim.conf has the following settings:"
	echo
	echo "KeyTable           /etc/opendkim/KeyTable"
	echo "SigningTable       /etc/opendkim/SigningTable"
	echo "ExternalIgnoreList /etc/opendkim/TrustedHosts"
	echo "InternalHosts      /etc/opendkim/TrustedHosts"
	echo
	
	sleep 1
	
    else
        echo
        echo "Please inform only 'y' or 'n'!"
        echo
	exit
    fi
fi



##
# Check for SOCKET configurations:
##

cp /etc/default/opendkim /etc/default/opendkim.saved.${SELECTOR_VAR}

grep "SOCKET=inet" /etc/default/opendkim | grep -v "#" > /dev/null

if [ $? == 1 ]; then

    echo "SOCKET=inet:8891@localhost" >> /etc/default/opendkim

else
    
    echo
    echo "I've found non-default SOCKET configuration, check below:"

    grep "SOCKET=inet" /etc/default/opendkim | grep -v "#" 

    echo
    echo "The SOCKET section which this script uses is:"
    echo "SOCKET=inet:8891@localhost"
    echo
    echo "Do you want me to comment the line(s) and add my configuration? (y/n)"

    read var

    if [ $var == "y" ] || [ $var == "Y" ]; then
	sed -i.bak '/SOCKET=inet/ s/^/#/g' /etc/default/opendkim
	echo "SOCKET=inet:8891@localhost" >> /etc/default/opendkim
	echo "Ok!"
	echo
    elif [ $var == "n" ] || [ $var == "N" ]; then
        echo "Skipping..."
        sleep 1
    else
        echo
        echo "Please inform only 'y' or 'n'!"
        echo
        exit
    fi
fi


##
# Do the Magik!
##

if [ -f /etc/opendkim/TrustedHosts ]; then
    cp /etc/opendkim/TrustedHosts /etc/opendkim/TrustedHosts.saved.${SELECTOR_VAR}
fi

echo "127.0.0.1
localhost
x.253.204.64
x.253.204.32/27" > /etc/opendkim/TrustedHosts



if [ ! -d /etc/opendkim/keys/${DOMAIN_DKIM} ]; then
    mkdir -p /etc/opendkim/keys/${DOMAIN_DKIM}
    opendkim-genkey -D /etc/opendkim/keys/${DOMAIN_DKIM} -d ${DOMAIN_DKIM} -s ${SELECTOR_VAR}
    GENERATED=0
else
    echo
    echo "The key directory for ${DOMAIN_DKIM} exists."
    echo "Do you want me to generate a new key? (y/n)"
	
    read var

    if [ $var == "y" ] || [ $var == "Y" ]; then
	rm -rf /etc/opendkim/keys/${DOMAIN_DKIM}
	mkdir -p /etc/opendkim/keys/${DOMAIN_DKIM}
        opendkim-genkey -D /etc/opendkim/keys/${DOMAIN_DKIM} -d ${DOMAIN_DKIM} -s ${SELECTOR_VAR}
	GENERATED=0
    elif [ $var == "n" ] || [ $var == "N" ]; then
        echo "Skipping..."
	GENERATED=1
        sleep 1
    else
        echo
        echo "Please inform only 'y' or 'n'!"
        echo
        exit
    fi
fi


##
# Correct the key permission:
##

if [ $GENERATED == 0 ]; then

    chown opendkim:opendkim /etc/opendkim/keys/${DOMAIN_DKIM}/${SELECTOR_VAR}.private

    if [ -f /etc/opendkim/KeyTable ]; then
    	cp /etc/opendkim/KeyTable /etc/opendkim/KeyTable.saved.${SELECTOR_VAR}
    fi

    echo "${SELECTOR_VAR}._domainkey.${DOMAIN_DKIM} ${DOMAIN_DKIM}:${SELECTOR_VAR}:/etc/opendkim/keys/${DOMAIN_DKIM}/${SELECTOR_VAR}.private" >> /etc/opendkim/KeyTable



    if [ -f /etc/opendkim/SigningTable ]; then
        cp /etc/opendkim/SigningTable /etc/opendkim/SigningTable.saved.${SELECTOR_VAR}
    fi

    echo "${DOMAIN_DKIM} ${SELECTOR_VAR}._domainkey.${DOMAIN_DKIM}" >> /etc/opendkim/SigningTable

fi

echo
echo "Please, check if the contents of the files KeyTable and SigningTable"
echo "do not have old or duplicate entries. They're located at /etc/opendkim"
echo


if [  $GENERATED == 0 ]; then

    echo
    echo "The selector for the ${DOMAIN_DKIM} is: ${SELECTOR_VAR}"
    echo
    echo "You should now add the following into ${DOMAIN_DKIM} DNS zone:"
    echo
    
    cat /etc/opendkim/keys/${DOMAIN_DKIM}/${SELECTOR_VAR}.txt
fi

echo
echo "Consider to implement Opendkim in your mailserver
you must do this or all of my effort will be useless"

if [ -d /etc/postfix ]; then
    echo
    echo "I've found Postfix!"
    echo
    
    echo "Check if you main.cf have those configurations:"
    echo
    echo "milter_default_action = accept"
    echo "milter_protocol = 2"
    echo "smtpd_milters = inet:localhost:8891"
    echo "non_smtpd_milters = inet:localhost:8891"

    echo
    echo "Check if your master.cf have the following line:"
    echo "  -o smtpd_milters=inet:127.0.0.1:8891"
    echo
    echo "below this line:"
    echo "smtp      inet  n       -       -       -       -       smtpd"
    echo
fi



##
# Validate Opendkim configuration and restart the service.
##

systemctl start opendkim
systemctl enable opendkim

echo "Please run manually the following commands:"
echo
echo "/lib/opendkim/opendkim.service.generate"
echo "systemctl daemon-reload"
echo "systemctl restart opendkim && systemctl restart postfix"
echo
echo "Opendkim is configured!"
