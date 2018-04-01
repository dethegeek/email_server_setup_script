#!/bin/bash

upgradeSystem()
{
    echo "Updating system"
    apt-get update
    apt-get upgrade -y
}
