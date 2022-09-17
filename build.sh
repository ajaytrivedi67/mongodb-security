#! /bin/bash
# Copyright 2019-present Kuei-chun Chen. All rights reserved.

docker-compose down

docker build -t simagix/mongo-security:labs -f mongo/Dockerfile .

docker rmi -f $(docker images -f "dangling=true" -q)
