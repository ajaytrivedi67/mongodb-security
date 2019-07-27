docker-compose down

docker build -t simagix/kerberos -f kerberos/Dockerfile .
docker build -t simagix/openldap -f openldap/Dockerfile .
docker build -t simagix/mongo-kerberos -f mongo/Dockerfile .

docker rmi -f $(docker images -f "dangling=true" -q)
