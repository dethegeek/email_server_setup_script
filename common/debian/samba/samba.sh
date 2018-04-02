#!/bin/bash

samba_install()
{
    echo "Installing Samba"
    bind_install
    apt-get install -y samba
    error_check
}

#
# param name of the realm
# param NetBIOS name
#
samba_setup()
{
    if [ $# < 2 ];  then
        # too few arguments
        return 1
    fi
    echo "Configuring Samba"
    mv /etc/samba/smb.conf /etc/samba.smb.conf.stock
    samba-tool domain provision --use-rfc2307 --function-level=2008_R2 --dns-backend=BIND9_DLZ --server-role=dc --realm=$1 --domain=$2
    error_check
}

samba_installDnsBackend()
{
    bind_install dlz-ldap-enum
    if [ "$BIND_RESOLUTION_MODE" = "resolve" ]; then
        echo "Using recursive resolution mode"
        bind_setupResolver
    elif [ "$BIND_RESOLUTION_MODE" = "forward" ]; then
        echo "Using a forwarder"
        bind_setupForwarder "$BIND_FORWARDER"
    else
        echo "Invalid setting resolution mode $BIND_RESOLUTION_MODE"
    fi
    local patch=$(mktemp /tmp/patch.XXXXXXXXXXXX)
    SAMBA_VAR="$SAMBA_VAR" envsubst < common/debian/samba/bind_add_keytab.patch > $patch
    patch --directory=/etc/bind -p1 < $patch
}