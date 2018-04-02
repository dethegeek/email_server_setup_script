#!/bin/bash

. ./common/tools.sh

#
# load configuration
#

. ./config/samba.stock.sh
if [ -f ./config/samba.sh ]
then
    if [ -x ./config/samba.sh ]
    then
        . ./config/samba.sh
    fi
fi
detectDistro
echo 0

. ./common/$DISTRO/samba/samba.sh
. ./common/$DISTRO/bind/bind.sh

echo "You are about to install and configure Samba 4 as domain controller with ISC Bind as DNS backend"
echo "This script was made for Debian 9"

upgradeSystem
samba_install
samba_setup $UPPER_SAMBA_DOMAIN $SAMBA_NETBIOS_DOMAIN
samba_installDnsBackend
exit 0

