#!/bin/bash

bind_install()
{
    echo "Installing ISC Bind"
    apt-get install -y bind9 $1
}

bind_getVersion()
{
    local bindVersion=$(named -v|cut -f 2 -d " "|cut -f 1 -d "-")
    echo $bindVersion
}

bind_getMinorVersion()
{
    local minor=$($(bind_getVersion)|cut -f 2 -d ".")
    echo $minor
}


bind_setupResolver()
{
    apt-get install -y wget cron
    (crontab -l -u root 2>/dev/null; echo "0 5 1 * * wget -q -O /etc/bind/db.root http://www.internic.net/zones/named.root") | crontab -u root -
    wget -q -O /etc/bind/db.root http://www.internic.net/zones/named.root
}

#
# param forwarders to use for ISC Bind
#
bind_setupForwarder()
{
    if [ $# < 1 ];  then
        # too few arguments
        return 1
    fi
    echo "Adding forwarders to ISC Bind"
    export FORWARDERS=$1
    local patch=$(mktemp /tmp/patch.XXXXXXXXXXXX)
    envsubst '${forwarders}' < common/debian/bind/forwarders.patch > $patch
    patch --directory=/etc/bind -p1 < $patch
    export FORWARDERS=
}