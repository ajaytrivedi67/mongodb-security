#!/bin/bash
# openssl req -x509 -nodes -days 3650 -newkey rsa:2048 -keyout selfsigned.key -out selfsigned.crt
echo "127.0.0.1	localhost" > /etc/hosts
echo "$(ping -c 1 kmip|head -1|cut -d'(' -f2|cut -d')' -f1)  kmip.simagix.com kmip" >> /etc/hosts
echo "$(ping -c 1 mongo|head -1|cut -d'(' -f2|cut -d')' -f1)  mongo.simagix.com mongo" >> /etc/hosts
pykmip-server