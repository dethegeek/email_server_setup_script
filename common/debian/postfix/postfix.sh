#Â!/bin/bash

# This installer is partially based on a gist from solusipse: https://gist.github.com/solusipse/7ed8e1da104baaee3f05
# with enhancements from the following forks:
# - https://gist.github.com/MarcelFox/6f4e68af1d4ca3c92a423d57a3bc4d42

installPostfix()
{
    echo "Installing Postfix"
    apt-get install -y postfix postfix-ldap
}

postfixLdap()
{
    touch /etc/postfix/ldap-users.cf
    chgrp postfix /etc/postfix/ldap-users.cf
    chmod 640 /etc/postfix/ldap-users.cf
    cat <<EOT >/etc/postfix/ldap-users.cf
server_host = $LDAP_SERVER
server_port = 389

# without TLS
version = 2

#with TLS
# version = 3
# start_tls = yes
# tls_ca_cert_file = /path/to/file
# tls_cert = /path/to/file
# tls_key = /path/to/file
# tls_require_cert = no
# tls_random_file = /dev/random
# tls_cipher_suite =

debuglevel = 0
bind = yes
bind_dn = $LDAP_USER_POSTFIX
bind_pw = $LDAP_USER_PASSWD
search_base = $AD_BASE
scope = sub
timeout = 10
# query_filter = mailacceptinggeneralid=%s
query_filter = (&(&(objectCategory=person)(sAMAccountName=%u))(!(userAccountControl:1.2.840.113556.1.4.$
# query_filter = (&(objectclass=person)(mail=%s))
# result_attribute = maildrop
#result_attribute = sAMAccountName
result_attribute = mail
# the trailing slash is required 
result_format = $MAIL_DOMAIN/%u/Maildir/
EOT
}

