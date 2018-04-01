#!/bin/bash

ESC_SEQ="\x1b["
COL_RESET=$ESC_SEQ"39;49;00m"
COL_RED=$ESC_SEQ"31;01m"
COL_GREEN=$ESC_SEQ"32;01m"
COL_YELLOW=$ESC_SEQ"33;01m"

DISTRO=unknown

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
    echo "Detecting your distribution (stub)"
    echo "Debian detected"
    DISTRO=debian
    error_check
    . ./common/$DISTRO/common.sh
}


