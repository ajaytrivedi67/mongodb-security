#! /bin/bash
# Copyright 2019-present Kuei-chun Chen. All rights reserved.

docker-compose down

ver=$(cat version)
docker build -t simagix/kerberos -f kerberos/Dockerfile .
docker build -t simagix/openldap -f openldap/Dockerfile .
docker build -t simagix/mongo-security:latest -t simagix/mongo-security:${ver} -f mongo/Dockerfile .
docker build -t simagix/pykmip -f pykmip/Dockerfile .

docker rmi -f $(docker images -f "dangling=true" -q)
