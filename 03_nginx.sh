#!/bin/bash
# I use it on blank Debian installation to setup nginx with php support for simple tasks.

ESC_SEQ="\x1b["
COL_RESET=$ESC_SEQ"39;49;00m"
COL_RED=$ESC_SEQ"31;01m"
COL_GREEN=$ESC_SEQ"32;01m"
COL_YELLOW=$ESC_SEQ"33;01m"

if [ "$UID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

function error_check {
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

echo "Updating system"
apt-get update
apt-get upgrade

apt-get install nginx php5-fpm
error_check

useradd -m -G users -s /bin/bash www
error_check

echo "server {
        root /home/www;
        index index.php index.html index.htm;

        location / {
                index index.php index.html index.htm;
                autoindex on;
        }

        location ~ \.php$ {
                fastcgi_split_path_info ^(.+\.php)(/.+)$;
                fastcgi_pass unix:/var/run/php5-fpm.sock;
                fastcgi_index index.php;
                include fastcgi_params;
        }
}" > /etc/nginx/sites-available/default
error_check

/etc/init.d/nginx start
/etc/init.d/php5-fpm start