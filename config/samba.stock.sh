#!/bin/bash

#
# configuration example
# copy this file to samba.sh to override some or all of these settings
#
SAMBA_DOMAIN=intra.example.com
UPPER_SAMBA_DOMAIN=INTRA.EXAMPLE.COM
SAMBA_NETBIOS_DOMAIN=INTRA

# allowed values are forward or resolve
BIND_RESOLUTION_MODE=resolve
BIND_FORWARDER=8.8.8.8

#
# these settings should NOT be overriden
#
SAMBA_VAR=/var/lib/samba