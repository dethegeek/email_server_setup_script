#!/bin/bash

installSamba()
{
    echo "Installing Samba"
    apt-get install -y samba
    error_check
}

setupSamba()
{
    echo "Configuring Samba"
    mv /etc/samba/smb.conf /etc/samba.smb.conf.stock
    samba-tool domain provision --use-rfc2307 --function-level=2008_R2 --dns-backend=BIND9_DLZ --server-role=dc --realm=$UPPER_SAMBA_DOMAIN --domain=$SAMBA_NETBIOS_DOMAIN
    error_check
}

installDnsBackend()
{
    echo "Configuring ISC Bind"
    apt-get install -y bind9 dlz-ldap-enum
    if [ "$BIND_RESOLUTION_MODE" = "resolve"]
    then
        echo "Using  recursive resolution mode"
        apt-get install -y wget cron
        (crontab -l -u root 2>/dev/null; echo "0 5 1 * * wget -q -O /etc/bind/db.root http://www.internic.net/zones/named.root") | crontab -u root -
        wget -q -O /etc/bind/db.root http://www.internic.net/zones/named.root
    fi
    if [ "$BIND_RESOLUTION_MODE" = "forward"]
    then
        echo "Using a forwarder"
        patch=$(mktemp /tmp/patch.XXXXXXXXXXXX)
        cat <<EOT >$patch
diff --git a/named.conf.options b/named.conf.options
index b1bef51..9e3679b 100644
--- a/named.conf.options
+++ b/named.conf.options
@@ -10,9 +10,9 @@ options {
        // Uncomment the following block, and insert the addresses replacing
        // the all-0's placeholder.

-       // forwarders {
-       //      0.0.0.0;
-       // };
+       forwarders {
+               ${BIND_FORWARDER};
+       };

        //========================================================================
        // If BIND logs error messages about the root key being expired,
EOT
        patch --directory=/etc/bind -p1 < $patch
    fi
}