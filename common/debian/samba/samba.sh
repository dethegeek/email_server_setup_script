#!/bin/bash

installSamba()
{
    echo "Installing Samba"
    apt-get install -y samba
}

setupSamba()
{
    mv /etc/samba/smb.conf /etc/samba.smb.conf.stock
    samba-tool domain provision --use-rfc2307 --function-level=2008_R2 --dns-backend=BIND9_DLZ --server-role=dc --realm=$UPPER_SAMBA_DOMAIN --domain=$SAMBA_NETBIOS_DOMAIN
}

installDnsBackend()
{
    apt-get install -y bind9 dlz-ldap-enum
}