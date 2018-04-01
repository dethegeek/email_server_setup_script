#!/bin/bash

. ./common/common.sh
. ./common/tools.sh

if [ "$UID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

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

. ./common/$DISTRO/samba/samba.sh

echo "You are about to install and configure Samba 4 as domain controller with ISC Bind as DNS backend"
echo "This script was made for Debian 9"

upgradeSystem
installSamba
setupSamba
installDnsBackend
exit 0

