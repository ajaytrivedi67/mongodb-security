#! /bin/bash
# Copyright 2019-present Kuei-chun Chen. All rights reserved.

docker-compose down

ver=$(cat version)
docker build -t simagix/kerberos:${ver} -t simagix/kerberos -f kerberos/Dockerfile .
docker build -t simagix/openldap:${ver} -t simagix/openldap -f openldap/Dockerfile .
docker build -t simagix/mongo-security:${ver} -t simagix/mongo-security -f mongo/Dockerfile .
docker build -t simagix/pykmip:${ver} -t simagix/pykmip -f pykmip/Dockerfile .

docker rmi -f $(docker images -f "dangling=true" -q)
