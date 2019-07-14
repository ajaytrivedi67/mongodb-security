#! /bin/bash
# Copyright 2019 Kuei-chun Chen. All rights reserved.
: ${REALM:=EXAMPLE.COM}
: ${ADMIN_USER:=admin}
: ${ADMIN_PASSWORD:=admin}
: ${SHARED:=/repo}

AUTH_MECHANISM="$2"
mkdir -p /var/log/mongodb /var/log/kerberos
# Create an user
mongod --dbpath /data/db --logpath /var/log/mongodb/mongod.log --bind_ip_all --fork
mongo mongodb://localhost/ --eval "db.getSisterDB('admin').createUser({ \
  user: 'admin', \
  pwd: 'secret', \
  roles: [ 'root' ]})"

mongo mongodb://localhost/ --eval "db.getSisterDB('\$external').createUser({ \
  user: 'mdb@${REALM}', \
  roles: [ { role: 'readWrite', db: 'admin' } ]})"

mongo mongodb://localhost/ --eval "db.getSisterDB('admin').createRole({ \
  role: 'cn=DBAdmin,ou=Groups,dc=simagix,dc=local', \
  privileges: [], \
  roles: [ 'userAdminAnyDatabase', 'clusterAdmin', 'readWriteAnyDatabase', 'dbAdminAnyDatabase' ] })"
mongo 'mongodb://localhost/admin' --eval 'db.shutdownServer()'

# Enable TLS
echo "TLS_REQCERT never" >> /etc/openldap/ldap.conf
echo "TLS_CACERT /server.pem" >> /etc/openldap/ldap.conf
cp /ldap.simagix.com.pem /server.pem
echo "authMechanism=$AUTH_MECHANISM"

if [ "$AUTH_MECHANISM" == "GSSAPI" ]; then
  # Create princials
  pass=$ADMIN_PASSWORD
  #pass=$(openssl rand -hex 8)
  mkdir -p $SHARED
  keytab="$SHARED/mongodb.keytab"
  # principal for mongod
  kadmin -r $REALM -p $ADMIN_USER/admin -w $ADMIN_PASSWORD addprinc -pw $pass mongodb/mongo-gssapi.simagix.com
  printf "%b" "addent -password -p mongodb/mongo-gssapi.simagix.com -k 1 -e aes256-cts\n$pass\nwrite_kt $keytab" | ktutil

  # Start mongod with auth and GSSAPI
  cp /mongo-gssapi.simagix.com.pem /mongo.pem
  echo "# set parameters" >> /etc/mongod.conf
  echo "setParameter:" >> /etc/mongod.conf
  echo " authenticationMechanisms: GSSAPI" >> /etc/mongod.conf
  env KRB5_KTNAME=$keytab mongod -f /etc/mongod.conf

  # principal for user
  clientkt="$SHARED/mdb.keytab"
  kadmin -r $REALM -p $ADMIN_USER/admin -w $ADMIN_PASSWORD addprinc -pw $pass mdb
  # use ktutil to create a keyfile for mongod to use
  printf "%b" "addent -password -p mdb -k 1 -e aes256-cts\n$pass\nwrite_kt $clientkt" | ktutil
  kinit mdb@$REALM -kt $clientkt

  # test Kerberos using a connection string, %2f: / and %40: @
  mongo "mongodb://mdb%40$REALM:xxx@mongo-gssapi.simagix.com/?authMechanism=GSSAPI&authSource=\$external" \
    --ssl --sslCAFile /ca.crt --sslPEMKeyFile /client.pem \
    --eval 'db.getSisterDB("admin").getRoles()' || exit 1

elif [ "$AUTH_MECHANISM" == "PLAIN" ]; then
  cp /mongo-plain.simagix.com.pem /mongo.pem
  echo "# set parameters" >> /etc/mongod.conf
  echo "setParameter:" >> /etc/mongod.conf
  echo " authenticationMechanisms: PLAIN" >> /etc/mongod.conf
  mongod -f /etc/mongod.conf

  # test LDAP using a connection string, %2f: / and %40: @
  # login is mdb@SIMAGIX.COM to comply with userToDNMapping, or we can add more rules to userToDNMapping
  mongo "mongodb://mdb%40$REALM:secret@mongo-plain.simagix.com/?authMechanism=PLAIN&authSource=\$external" \
    --ssl --sslCAFile /ca.crt --sslPEMKeyFile /client.pem \
    --eval 'db.getSisterDB("admin").getRoles()' || exit 1

else
  cp /mongo-builtin.simagix.com.pem /mongo.pem
  mongod -f /etc/mongod.conf
  # test local login
  mongo "mongodb://admin:secret@mongo-builtin.simagix.com/?authSource=admin" \
    --ssl --sslCAFile /ca.crt --sslPEMKeyFile /client.pem \
    --eval 'db.getSisterDB("admin").getRoles()' || exit 1

fi

# keep the instance up
tail -1f /var/log/mongodb/mongod.log
