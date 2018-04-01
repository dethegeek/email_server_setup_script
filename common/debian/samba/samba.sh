#!/bin/bash

installSamba()
{
    echo "Installing Samba"
    apt-get install -y samba
}

setupSamba()
{
    samba-tool domain provision --use-rfc2307 --interactive --function-level=2008_R2 --dns-backend=BIND9_DLZ --server-role=dc --realm=$UPPER_SAMBA_DOMAIN
}