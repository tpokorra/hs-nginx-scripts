#!/bin/bash

source ~/scripts/config.sh

max_certificates_per_run=5
certs_dir="$HOME/nginx/certs"
USER=`id -nu`
PAC=$(echo $USER | awk '{split($0,a,"-"); print a[1]}')
PACHOSTNAME="$PAC.hostsharing.net"
listen80="$PACHOSTNAME:$NGINXPORT80"

if [ ! -d ~/letsencrypt ]
then
  mkdir ~/letsencrypt
fi

if [ ! -f ~/letsencrypt/acme_tiny.py ]
then
  wget https://raw.githubusercontent.com/diafygi/acme-tiny/master/acme_tiny.py -O ~/letsencrypt/acme_tiny.py
fi

if [ ! -f ~/letsencrypt/account.key ]
then
  openssl genrsa 4096 > ~/letsencrypt/account.key
fi

if [ ! -f ~/letsencrypt/lets-encrypt-x3-cross-signed.pem ]
then
  wget https://letsencrypt.org/certs/lets-encrypt-x3-cross-signed.pem -O ~/letsencrypt/lets-encrypt-x3-cross-signed.pem
fi

# create a new, unique Diffie-Hellman group, to fight the Logjam attack: https://weakdh.org/sysadmin.html
if [ ! -f $certs_dir/dhparams.pem ]
then
  mkdir -p $certs_dir
  openssl dhparam -out $certs_dir/dhparams.pem 2048
fi

if [ -z $1 ]
then
  echo "specify which domain should get a new lets encrypt certificate, or all"
  echo "$0 33-mydomain.com"
  echo "$0 all"
  exit -1
fi
domain=$1

function need_new_certificate {
domainconf=$1
domain=`basename $domainconf`
domain=${domain:0:-5}
need_new=0

crtfile=$certs_dir/$domain.crt

if [ ! -f $crtfile ]
then
  need_new=1
  return
fi

# TODO does the domain resolve to this host?

enddate=`openssl x509 -enddate -noout -in $crtfile | cut -d= -f2-`
# show date in readable format, eg. 2016-07-03
#date -d "$enddate" '+%F'
# convert to timestamp for comparison
enddate=`date -d "$enddate" '+%s'`
threeweeksfromnow=`date -d "+21 days" '+%s'`
echo "certificate valid till " `date +%Y-%m-%d -d @$enddate` $domain
if [ $enddate -lt $threeweeksfromnow ]
then
  need_new=1
fi
}

declare -A domain_counter
function new_letsencrypt_certificate {
domainconf=$1
domain=`basename $domainconf`
domain=${domain:0:-5}
posdash=`expr index "$domain" "-"`
domain=${domain:posdash}
challengedir=$certs_dir/tmp/$domain/challenge/.well-known/acme-challenge/

  # TODO this does not support toplevel domains like .co.uk, etc
  maindomain=`echo $domain | awk -F. '{print $(NF-1) "." $NF}'`
  maindomain=${maindomain/./_}
  counter=${domain_counter[$maindomain]}
  domain_counter[$maindomain]=$((${domain_counter[$maindomain]}+1))
  if [ ${domain_counter[$maindomain]} -gt $max_certificates_per_run ]
  then
    # To avoid hitting the limit of new certificates within a week per domain, we delay the certificate for the next run
    echo "delaying new certificate for $domain"
    return
  fi

  echo "new certificate for $domain"

  cd ~/letsencrypt
  openssl genrsa 4096 > $domain.key
  openssl req -new -sha256 -key $domain.key -subj "/CN=$domain" > $domain.csr
  mkdir -p ~/nginx/etc/conf.d/disabled
  for f in ~/nginx/etc/conf.d/*.conf; do mv $f ~/nginx/etc/conf.d/disabled; done
  cat > $domainconf << FINISH
server {
    listen $listen80;
    server_name $domain;
    location /.well-known/acme-challenge/ { root $certs_dir/tmp/$domain/challenge; }
}
FINISH

  mkdir -p $challengedir
  cat $domainconf
  ~/scripts/restart.sh
  sleep 3
  error=0
  python acme_tiny.py --account-key ./account.key --csr ./$domain.csr --acme-dir $challengedir > ./$domain.crt || error=1
  rm -Rf $certs_dir/tmp/$cid
  for f in ~/nginx/etc/conf.d/disabled/*; do mv $f ~/nginx/etc/conf.d; done

  if [ $error -ne 1 ]
  then
    cp -f $domain.key $certs_dir/$domain.key
    cat $domain.crt lets-encrypt-x3-cross-signed.pem > $certs_dir/$domain.crt
  fi

  ~/scripts/restart.sh
  cd -

  if [ $error -eq 1 ]
  then
    exit -1
  fi
}

if [ "$domain" == "all" ]
then
  for f in ~/nginx/etc/conf.d/*
  do
    if [ -f $f ]
    then
      if [ "`cat $f | grep ssl`" != "" ]
      then
        need_new_certificate $f
        if [ $need_new -eq 1 ]
        then
          new_letsencrypt_certificate $f
        fi
      fi
    fi
  done
else
  new_letsencrypt_certificate ~/nginx/etc/conf.d/$domain.conf
fi

