NGINX als Reverse Proxy bei Hostsharing
=======================================

Diese Skripte sind als Ergänzung zum Wiki Artikel gedacht: https://wiki.hostsharing.net/index.php?title=NGinX_installieren

Benutzung als Benutzer xyz00-nginx:
    
    cd ~
    git clone https://github.com/tpokorra/hs-nginx-scripts.git scripts
    cd scripts
    # Einrichtung mit den entsprechenden Ports für den umgeleiteten Port für 80 bzw. 443
    ./init.sh 32080 32443

Funktionen von init.sh:
* init.sh wird supervisord einrichten, und nginx starten.
* Es werden auch die entsprechenden Cronjobs für letsencrypt und supervisor eingerichtet.

Weitere Webseite hinzufügen:

    # wir wollen auf die Domain test01.example.org hören, und der Reverse Proxy geht auf Port 40001
    ~/scripts/addwebsite.sh test01.example.org 40001

Zum Testen einen Python Server auf Port 40001 starten, in einem Verzeichnis wo eine index.html liegt:

    python3 -m http.server --bind localhost 40001

Webseiten werden mit Letsencrypt eingerichtet, mit dem HTTP Challenge Verfahren.

Es kann aber auch ein Wildcard Zertifikat hinterlegt werden, z.B. ~/nginx/certs/wildcard.example.org.crt und .key
