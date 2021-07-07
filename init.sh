#/bin/bash

if [ -z $2 ]; then
  echo "call: $0 HTTPPort HTTPSPort"
  echo "eg: $0 32080 32443"
  exit
fi

NGINXPORT80=$1
NGINXPORT443=$2
NGINXPATH=$HOME/nginx
SUPERVISORPATH=$HOME/supervisor

if [ -f ~/nginx/etc/nginx.conf ]; then
    echo "there is already a configuration"
    exit
fi
if [ -f ~/supervisor/etc/supervisord.conf ]; then
    echo "there is already a configuration"
    exit
fi
if [[ "`crontab -l | grep letsencrypt`" -ne "" ]]; then
    echo "there is already a configuration"
    exit
fi

mkdir -p ~/nginx/etc
mkdir -p ~/nginx/log
mkdir -p ~/nginx/run
mkdir -p ~/nginx/certs

cat ~/scripts/templates/config.sh.tpl | \
    sed "s#MYPORT80#$NGINXPORT80#g" | \
    sed "s#MYPORT443#$NGINXPORT443#g" \
    > ~/scripts/config.sh

cat ~/scripts/templates/nginx.conf.tpl | \
    sed "s#NGINXPATH#$NGINXPATH#g" \
    > ~/nginx/etc/nginx.conf

mkdir -p ~/supervisor/etc
mkdir -p ~/supervisor/log
mkdir -p ~/supervisor/run

cat ~/scripts/templates/supervisord.conf.tpl | \
    sed "s#NGINXPATH#$NGINXPATH#g" | \
    sed "s#SUPERVISORPATH#$SUPERVISORPATH#g" \
    > ~/supervisor/etc/supervisord.conf

crontab -l | { cat; echo "55 8 * * * $HOME/scripts/letsencrypt.sh all"; } | crontab -
crontab -l | { cat; echo "@reboot  $HOME/scripts/start.sh"; } | crontab -

~/scripts/start.sh
