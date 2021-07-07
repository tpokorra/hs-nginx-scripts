#!/bin/bash

source ~/scripts/config.sh

if [ -z $2 ]; then
  echo "call: $0 domain port"
  echo "eg: $0 www.example.org 34001"
  exit
fi

DOMAIN=$1
APPPORT=$2
USER=`id -nu`
PAC=$(echo $USER | awk '{split($0,a,"-"); print a[1]}')
PACHOSTNAME="$PAC.hostsharing.net"
NGINXLOGPATH=$HOME/nginx/log
CERTSPATH=$HOME/nginx/certs

wildcardurl="wildcard".$( echo $DOMAIN | cut -d '.' -f 2- )
if [ -f $CERTSPATH/$wildcardurl.crt ]; then
  generateCert=0
  CERTNAME=$wildcardurl
elif [ -f $CERTSPATH/$DOMAIN.crt ]; then
  generateCert=0
  CERTNAME=$DOMAIN
else
  generateCert=1
  CERTNAME=$DOMAIN
fi

mkdir -p ~/nginx/etc/conf.d
cat ~/scripts/templates/nginx.sslconf.tpl | \
    sed "s/PACHOSTNAME/$PACHOSTNAME/g" | \
    sed "s/NGINXPORT80/$NGINXPORT80/g" | \
    sed "s/NGINXPORT443/$NGINXPORT443/g" | \
    sed "s/DOMAIN/$DOMAIN/g" | \
    sed "s#NGINXLOGPATH#$NGINXLOGPATH#g" | \
    sed "s#CERTSPATH#$CERTSPATH#g" | \
    sed "s/CERTNAME/$CERTNAME/g" | \
    sed "s#APPPORT#$APPPORT#g" \
    > ~/nginx/etc/conf.d/$DOMAIN.conf

if [ $generateCert -eq 1 ]
then
  ~/scripts/letsencrypt.sh $DOMAIN
fi

