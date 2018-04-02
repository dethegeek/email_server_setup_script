#!/bin/bash

set -e

ESC_SEQ="\x1b["
COL_RESET=$ESC_SEQ"39;49;00m"
COL_RED=$ESC_SEQ"31;01m"
COL_GREEN=$ESC_SEQ"32;01m"
COL_YELLOW=$ESC_SEQ"33;01m"

DISTRO=
DISTRO_VER=
DISTRO_ARCH=

if [ "$UID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

error_check() {
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

# need a function to detect the distro of GNU/Linux
# and load the appropriate tools (debian, red hat, ...)

detectDistro()
{
    echo "Detecting your distribution"
    DISTRO=$(getDistributionName)
    DISTRO_VER=$(getDistributionVersion)
    DISTRO_ARCH=$(getDistributionArchitecture)
    local fail=
    if [ "$DISTRO" = "" ]
    then
        fail="Unable to detect the distribution"
    fi
    if [ "$DISTRO_VER" = "" ]
    then
        fail="Unable to detect the version of $DISTRO"
    fi
    if [ "$DISTRO_ARCH" = "" ]
    then
        fail="Unable to detect  the architecture of $DISTRO $DISTRO_VER"
    fi
    if [ "$fail" != "" ];  then
        echo "$fail"
        exit 1
    fi
    echo - detected $DISTRO, version $DISTRO_VERSION, architecture $DISTRO_ARCH

    if [ -f ./common/$DISTRO/common.sh ]; then
        . ./common/$DISTRO/common.sh
    else
        echo "System not supported. Please contribute."
        return 1
    fi

    checkDependencies
}

# https://unix.stackexchange.com/questions/6345/how-can-i-get-distribution-name-and-version-number-in-a-simple-shell-script
# shall return the distribution name with lowercase (to match the matching folder)
getDistributionName()
{
    local os=
    if [ -f /etc/os-release ]; then
        # freedesktop.org and systemd
        . /etc/os-release
        os=$ID
    elif type lsb_release >/dev/null 2>&1; then
        # linuxbase.org
        os=$(lsb_release -si)
    elif [ -f /etc/lsb-release ]; then
        # For some versions of Debian/Ubuntu without lsb_release command
        . /etc/lsb-release
        os=$DISTRIB_ID
    elif [ -f /etc/debian_version ]; then
        # Older Debian/Ubuntu/etc.
        os=debian
    elif [ -f /etc/SuSe-release ]; then
        # Older SuSE/etc.
        os=
    elif [ -f /etc/redhat-release ]; then
        # Older Red Hat, CentOS, etc.
        os=
    else
        # Fall back to uname, e.g. "Linux <version>", also works for BSD, etc.
        os=$(uname -s)
    fi
    echo $os
}

# https://unix.stackexchange.com/questions/6345/how-can-i-get-distribution-name-and-version-number-in-a-simple-shell-script
# shall return a number
getDistributionVersion()
{
    local ver=
    if [ -f /etc/os-release ]; then
        # freedesktop.org and systemd
        . /etc/os-release
        ver=$VERSION_ID
    elif type lsb_release >/dev/null 2>&1; then
        # linuxbase.org
        ver=$(lsb_release -sr)
    elif [ -f /etc/lsb-release ]; then
        # For some versions of Debian/Ubuntu without lsb_release command
        . /etc/lsb-release
        ver=$DISTRIB_RELEASE
    elif [ -f /etc/debian_version ]; then
        # Older Debian/Ubuntu/etc.
        ver=$(cat /etc/debian_version)
    elif [ -f /etc/SuSe-release ]; then
        # Older SuSE/etc.
        ver=
    elif [ -f /etc/redhat-release ]; then
        # Older Red Hat, CentOS, etc.
        ver=
    else
        # Fall back to uname, e.g. "Linux <version>", also works for BSD, etc.
        ver=$(uname -r)
    fi
    echo $ver
}

getDistributionArchitecture()
{
    local arch=
    case $(uname -m) in
    x86_64)
        arch=x64  # or AMD64 or Intel64 or whatever
        ;;
    i*86)
        arch=x86  # or IA32 or Intel32 or whatever
        ;;
    *)
        # leave ARCH as-is
        arch=unknown
        ;;
    esac
    echo $arch
}

checkDependencies()
{
    local dependenciesOk=1
    local patchBin=$(which patch)
    local envsubstBin=$(which envsubst)
    if [ "$envsubstBin" = "" ]; then
        echo "I need gettext"
        dependenciesOk=0
    fi
    if [ "$patchBin" = "" ]; then
        echo "I need patch"
        dependenciesOk=0
    fi
    if [ "$dependenciesOk" != "1" ]; then
        return 1
    fi
}