#!/bin/bash

ESC_SEQ="\x1b["
COL_RESET=$ESC_SEQ"39;49;00m"
COL_RED=$ESC_SEQ"31;01m"
COL_GREEN=$ESC_SEQ"32;01m"
COL_YELLOW=$ESC_SEQ"33;01m"

if [ "$UID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

function error_check {
    if [ "$?" = "0" ]; then
        echo -e "$COL_GREEN OK. $COL_RESET"
    else
        echo -e "$COL_RED An error has occured. $COL_RESET"
        read -p "Press enter or space to ignore it. Press any other key to abort." -n 1 key

        if [[ $key != "" ]]; then
            exit
        fi
    fi
}


echo "You are about to install and configure Postfix virtual system with imap support (via Dovecot)."
echo "This script was made for Debian 7, but was adapted for Debian 9 [25/07/2017]."

echo "Updating system"
apt-get update
apt-get upgrade

echo "Adding group:"
groupadd -g 5000 vmail
error_check

echo "Adding group:"
useradd -u 5000 -g vmail -s /usr/bin/nologin -d /home/vmail -m vmail
error_check

echo "Installing programs:"
apt-get install postfix dovecot-core dovecot-imapd postgresql postfix-pgsql dovecot-lmtpd dovecot-pgsql php7.0-fpm php7.0-imap php7.0-pgsql php7.0-mcrypt php7.0-intl php7.0-mbstring php7.0-xml
error_check

#echo "Preparing database:"

DBPASS=$(date | md5sum | head -c 32)
#CREATEUSER="CREATE USER postfix_user WITH PASSWORD '${DBPASS}';"
#CREATEDB="CREATE DATABASE postfix_db;"
#PERMISSDB="GRANT ALL PRIVILEGES ON DATABASE postfix_db TO postfix_user;"

#sudo -u postgres psql -c "${CREATEUSER}"
#error_check
#sudo -u postgres psql -c "${CREATEDB}"
#error_check
#sudo -u postgres psql -c "${PERMISSDB}"
#error_check

echo
echo "Please inform the main domain of your server, like 'example.com'"

read MAIN_DOMAIN

echo
echo "Please inform the Hostname of your machine like 'hostname.example.com'"
echo "It'll be needed to add an A entry for the hostname on the DNS zone"
echo

read HOST_NAME

echo "Creating postfix config files (/etc/postfix/main.cf):"
echo "myhostname = ${HOST_NAME}
mydomain = ${MAIN_DOMAIN}
mydestination = \$myhostname, localhost.\$mydomain, localhost
relay_domains =
virtual_alias_maps = proxy:pgsql:/etc/postfix/virtual_alias_maps.cf
virtual_mailbox_domains = proxy:pgsql:/etc/postfix/virtual_mailbox_domains.cf
virtual_mailbox_maps = proxy:pgsql:/etc/postfix/virtual_mailbox_maps.cf
virtual_mailbox_base = /home/vmail
virtual_mailbox_limit = 512000000
virtual_minimum_uid = 5000
virtual_transport = dovecot
virtual_uid_maps = static:5000
virtual_gid_maps = static:5000
local_transport = dovecot
local_recipient_maps = \$virtual_mailbox_maps
transport_maps = hash:/etc/postfix/transport

milter_default_action = accept
milter_protocol = 2
smtpd_milters = inet:localhost:8891
non_smtpd_milters = inet:localhost:8891 

smtp_tls_security_level = may
smtpd_sasl_auth_enable = yes
smtpd_sasl_type = dovecot
smtpd_sasl_path = private/auth
smtpd_recipient_restrictions = permit_mynetworks, permit_sasl_authenticated, reject_unauth_destination
smtpd_sasl_security_options = noanonymous
smtpd_sasl_tls_security_options = \$smtpd_sasl_security_options
smtpd_tls_auth_only = yes
smtpd_tls_cert_file = /etc/ssl/private/server.crt
smtpd_tls_key_file = /etc/ssl/private/server.key
smtpd_sasl_local_domain = \$mydomain
broken_sasl_auth_clients = yes
smtpd_tls_loglevel = 1
html_directory = /usr/share/doc/postfix/html
queue_directory = /var/spool/postfix" > /etc/postfix/main.cf
message_size_limit = 52428800
error_check

echo "Creating postfix config files (/etc/postfix/master.cf):"
echo "#
# Postfix master process configuration file.  For details on the format
# of the file, see the master(5) manual page (command: "man 5 master").
#
# Do not forget to execute "postfix reload" after editing this file.
#
# ==========================================================================
# service type  private unpriv  chroot  wakeup  maxproc command + args
#               (yes)   (yes)   (yes)   (never) (100)
# ==========================================================================
smtp      inet  n       -       -       -       -       smtpd
  -o smtpd_milters=inet:127.0.0.1:8891
#smtp      inet  n       -       -       -       1       postscreen
#smtpd     pass  -       -       -       -       -       smtpd
#dnsblog   unix  -       -       -       -       0       dnsblog
#tlsproxy  unix  -       -       -       -       0       tlsproxy
submission inet n       -       -       -       -       smtpd
#  -o syslog_name=postfix/submission
  -o smtpd_tls_security_level=encrypt
  -o smtpd_sasl_auth_enable=yes
#  -o smtpd_client_restrictions=permit_sasl_authenticated,reject
#  -o milter_macro_daemon_name=ORIGINATING
smtps     inet  n       -       -       -       -       smtpd
#  -o syslog_name=postfix/smtps
  -o smtpd_tls_wrappermode=yes
  -o smtpd_sasl_auth_enable=yes
#  -o smtpd_client_restrictions=permit_sasl_authenticated,reject
#  -o milter_macro_daemon_name=ORIGINATING
#628       inet  n       -       -       -       -       qmqpd
pickup    fifo  n       -       -       60      1       pickup
cleanup   unix  n       -       -       -       0       cleanup
qmgr      fifo  n       -       n       300     1       qmgr
#qmgr     fifo  n       -       n       300     1       oqmgr
tlsmgr    unix  -       -       -       1000?   1       tlsmgr
rewrite   unix  -       -       -       -       -       trivial-rewrite
bounce    unix  -       -       -       -       0       bounce
defer     unix  -       -       -       -       0       bounce
trace     unix  -       -       -       -       0       bounce
verify    unix  -       -       -       -       1       verify
flush     unix  n       -       -       1000?   0       flush
proxymap  unix  -       -       n       -       -       proxymap
proxywrite unix -       -       n       -       1       proxymap
smtp      unix  -       -       -       -       -       smtp
relay     unix  -       -       -       -       -       smtp
#       -o smtp_helo_timeout=5 -o smtp_connect_timeout=5
showq     unix  n       -       -       -       -       showq
error     unix  -       -       -       -       -       error
retry     unix  -       -       -       -       -       error
discard   unix  -       -       -       -       -       discard
local     unix  -       n       n       -       -       local
virtual   unix  -       n       n       -       -       virtual
lmtp      unix  -       -       -       -       -       lmtp
anvil     unix  -       -       -       -       1       anvil
scache    unix  -       -       -       -       1       scache
#
# ====================================================================
# Interfaces to non-Postfix software. Be sure to examine the manual
# pages of the non-Postfix software to find out what options it wants.
#
# Many of the following services use the Postfix pipe(8) delivery
# agent.  See the pipe(8) man page for information about \${recipient}
# and other message envelope options.
# ====================================================================
#
# maildrop. See the Postfix MAILDROP_README file for details.
# Also specify in main.cf: maildrop_destination_recipient_limit=1
#
# To 'virtual' LDA:
#maildrop  unix  -       n       n       -       -       pipe
#  flags=DRhu user=vmail argv=/usr/bin/maildrop -d \${recipient}
#
# To Dovecot LDA:
dovecot   unix  -       n       n       -       -       pipe                                                                    
   flags=DRhu user=vmail:vmail argv=/usr/lib/dovecot/dovecot-lda -f \${sender} -d \${recipient}
#
# ====================================================================
#
# Recent Cyrus versions can use the existing \"lmtp\" master.cf entry.
#
# Specify in cyrus.conf:
#   lmtp    cmd=\"lmtpd -a\" listen=\"localhost:lmtp\" proto=tcp4
#
# Specify in main.cf one or more of the following:
#  mailbox_transport = lmtp:inet:localhost
#  virtual_transport = lmtp:inet:localhost
#
# ====================================================================
#
# Cyrus 2.1.5 (Amos Gouaux)
# Also specify in main.cf: cyrus_destination_recipient_limit=1
#
#cyrus     unix  -       n       n       -       -       pipe
#  user=cyrus argv=/cyrus/bin/deliver -e -r ${sender} -m \${extension} \${user}
#
# ====================================================================
# Old example of delivery via Cyrus.
#
#old-cyrus unix  -       n       n       -       -       pipe
#  flags=R user=cyrus argv=/cyrus/bin/deliver -e -m \${extension} \${user}
#
# ====================================================================
#
# See the Postfix UUCP_README file for configuration details.
#
uucp      unix  -       n       n       -       -       pipe
  flags=Fqhu user=uucp argv=uux -r -n -z -a\$sender - \$nexthop!rmail (\$recipient)
#
# Other external delivery methods.
#
ifmail    unix  -       n       n       -       -       pipe
  flags=F user=ftn argv=/usr/lib/ifmail/ifmail -r \$nexthop (\$recipient)
bsmtp     unix  -       n       n       -       -       pipe
  flags=Fq. user=bsmtp argv=/usr/lib/bsmtp/bsmtp -t\$nexthop -f\$sender \$recipient
scalemail-backend unix  -   n   n   -   2   pipe
  flags=R user=scalemail argv=/usr/lib/scalemail/bin/scalemail-store \${nexthop} \${user} \${extension}
mailman   unix  -       n       n       -       -       pipe
  flags=FR user=list argv=/usr/lib/mailman/bin/postfix-to-mailman.py
  \${nexthop} \${user}

cleanup   unix  n       -       -       -       0       cleanup
subcleanup unix n       -       -       -       0       cleanup
 -o header_checks=regexp:/etc/postfix/submission_header_checks
" > /etc/postfix/master.cf
error_check

echo "Creating postfix config files (/etc/postfix/submission_header_checks):"
echo "/^Received:/ IGNORE
/^User-Agent:/ IGNORE" > /etc/postfix/submission_header_checks
error_check

echo "Creating postfix config files (/etc/postfix/virtual_alias_maps.cf):"
echo "user = postfix_user
password = ${DBPASS}
hosts = localhost
dbname = postfix_db
query = SELECT goto FROM alias WHERE address='%s' AND active = true
" > /etc/postfix/virtual_alias_maps.cf
error_check

echo "Creating postfix config files (/etc/postfix/virtual_mailbox_domains.cf):"
echo "user = postfix_user
password = ${DBPASS}
hosts = localhost
dbname = postfix_db
query = SELECT domain FROM domain WHERE domain='%s' AND backupmx = false AND active = true
" > /etc/postfix/virtual_mailbox_domains.cf
error_check

echo "Creating postfix config files (/etc/postfix/virtual_mailbox_maps.cf):"
echo "user = postfix_user
password = ${DBPASS}
hosts = localhost
dbname = postfix_db
query = SELECT maildir FROM mailbox WHERE username='%s' AND active = true
" > /etc/postfix/virtual_mailbox_maps.cf
error_check

echo "Creating dovecot config files (/etc/dovecot/dovecot.conf):"
echo "protocols = imap
auth_mechanisms = plain
passdb {
    driver = sql
    args = /etc/dovecot/dovecot-sql.conf
}
userdb {
    driver = sql
    args = /etc/dovecot/dovecot-sql.conf
}
service auth {
    unix_listener /var/spool/postfix/private/auth {
        group = postfix
        mode = 0660
        user = postfix
    }
    user = root
}
mail_home = /home/vmail/%d/%u
mail_location = maildir:~
ssl_cert = </etc/ssl/private/server.crt
ssl_key = </etc/ssl/private/server.key" > /etc/dovecot/dovecot.conf
error_check

echo "Creating dovecot config files (/etc/dovecot/dovecot-sql.conf):"
echo "driver = pgsql
connect = host=localhost dbname=postfix_db user=postfix_user password=${DBPASS}
default_pass_scheme = MD5-CRYPT
user_query = SELECT '/home/vmail/%d/%u' as home, 'maildir:/home/vmail/%d/%u' as mail, 5000 AS uid, 5000 AS gid, concat('dirsize:storage=',  quota) AS quota FROM mailbox WHERE username = '%u' AND active = '1'
password_query = SELECT username as user, password, '/home/vmail/%d/%u' as userdb_home, 'maildir:/home/vmail/%d/%u' as userdb_mail, 5000 as  userdb_uid, 5000 as userdb_gid FROM mailbox WHERE username = '%u' AND active = '1'
" > /etc/dovecot/dovecot-sql.conf
error_check

echo "Creating postmap:"
touch /etc/postfix/transport
postmap /etc/postfix/transport
error_check

read -p "Enter Postfix Admin and Roundcube installation path: " DOWNPATH

if [ ! -d ${DOWNPATH} ]; then
    mkdir -p ${DOWNPATH}
fi

echo "Checking if path is correct:"
cd ${DOWNPATH}
error_check

echo "Downloading postfixadmin:"
wget -O postfixadmin.tar.gz http://sourceforge.net/projects/postfixadmin/files/latest/download
error_check

echo "Unpacking postfixadmin:"
tar xvf postfixadmin.tar.gz -C ${DOWNPATH}
error_check
rm -rf postfixadmin.tar.gz
mv postfixadmin-* postfixadmin
mkdir postfixadmin/templates_c
chown debian: postfixadmin/templates_c

echo "Setting permissions:"
chmod -R 777 postfixadmin/templates_c
error_check

echo "Downloading roundcube:"
wget https://github.com/roundcube/roundcubemail/releases/download/1.3.0/roundcubemail-1.3.0-complete.tar.gz
error_check

echo "Unpacking roundcube:"
tar xvf roundcubemail-1.3.0-complete.tar.gz -C ${DOWNPATH}
error_check

rm -rf roundcube.tar.gz
mv roundcubemail-* mail

chown -R www-data: mail/*
chown www-data mail/.htaccess
error_check


echo "Checking if php7.0-fpm is working:"
service php7.0-fpm restart
error_check

echo "Creating SSL certificate:"
cd /etc/ssl/private/
openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:2048 -out server.key
chmod 400 server.key
error_check

openssl req -new -key server.key -out server.csr
openssl x509 -req -days 365 -in server.csr -signkey server.key -out server.crt
chmod 444 server.crt
error_check

echo "Starting postfix daemon:"
/etc/init.d/postfix restart
error_check

echo "Starting dovecot daemon:"
/etc/init.d/dovecot restart
error_check

echo "Enabling services:"
update-rc.d postfix defaults
update-rc.d dovecot defaults
error_check


echo -e "$COL_GREEN Setup complete. $COL_RESET"
echo
echo "You should configure postfixadmin and roundcube."
echo "Use these settings:"
echo "database type: pgsql"
echo "database host: localhost"
echo "database user: postfix_user"
echo "database pass: ${DBPASS}"
echo "database name: postfix_db"
echo
echo "You must create the following database and user:"
echo
echo "USER: postfix_user"
echo "PASS: ${DBPASS}"
echo "DATABASE: postfix_db"
echo
echo "while in the postgres shell, you can create those with:"
echo "postgres# createuser -P postfix_user"
echo
echo "Past the password when it prompts"
echo
echo "postgres# createdb postfix_db -O postfix_user"
echo

