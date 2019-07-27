#! /bin/bash
# Copyright 2019 Kuei-chun Chen. All rights reserved.
: ${REALM:=EXAMPLE.COM}
: ${ADMIN_USER:=admin}
: ${ADMIN_PASSWORD:=secret}

AUTH_MECHANISM="$2"
mkdir -p /var/log/mongodb /var/log/kerberos /repo

seed_data() {
  mongod --dbpath /data/db --logpath /var/log/mongodb/mongod.log --bind_ip_all --fork
  mongo 'mongodb://localhost/' < /admin.js
}

# test scram login
auth_scram() {
  echo "==> SCRAM-SHA-1"
  mongo --quiet "mongodb://admin:secret@mongo.simagix.com/?authSource=admin" \
    --ssl --sslCAFile /ca.pem --sslPEMKeyFile /client.pem \
    --eval 'db.runCommand({connectionStatus : 1})'
}

auth_x509() {
  echo "==> MONGODB-X509"
  mongo --quiet "mongodb://CN=ken.chen%40simagix.com,OU=Users,O=Simagix,L=Atlanta,ST=Georgia,C=US:xxx@mongo.simagix.com/?authMechanism=MONGODB-X509&authSource=\$external" \
    --ssl --sslCAFile /ca.pem --sslPEMKeyFile /client.pem \
    --eval 'db.runCommand({connectionStatus : 1})'
}

# test LDAP
auth_ldap() {
  echo "==> PLAIN"
  # mdb user exists in $external database
  mongo --quiet "mongodb://mdb:secret@mongo.simagix.com/?authMechanism=PLAIN&authSource=\$external" \
    --ssl --sslCAFile /ca.pem --sslPEMKeyFile /client.pem \
    --eval 'db.runCommand({connectionStatus : 1})'
}

# test Kerberos
auth_gssapi() {
  echo "==> GSSAPI"
  # Use a connection string, %2f: / and %40: @
  kinit mdb@$REALM -kt $keytab
  mongo --quiet "mongodb://mdb%40$REALM:xxx@mongo.simagix.com/?authMechanism=GSSAPI&authSource=\$external" \
    --ssl --sslCAFile /ca.pem --sslPEMKeyFile /client.pem \
    --eval 'db.runCommand({connectionStatus : 1})'
}

# Enable TLS
echo "TLS_REQCERT never" >> /etc/openldap/ldap.conf
echo "TLS_CACERT /server.pem" >> /etc/openldap/ldap.conf
cp /ldap.simagix.com.pem /server.pem
echo "127.0.0.1	localhost" > /etc/hosts
# necessary for Kerberos reverse DNS lookup
echo "$(ping -c 1 kerberos|head -1|cut -d'(' -f2|cut -d')' -f1)  kerberos.simagix.com kerberos" >> /etc/hosts
echo "$(ping -c 1 ldap|head -1|cut -d'(' -f2|cut -d')' -f1)  ldap.simagix.com ldap" >> /etc/hosts
echo "$(ping -c 1 mongo|head -1|cut -d'(' -f2|cut -d')' -f1)  mongo.simagix.com mongo" >> /etc/hosts

pass="secret"
keytab="/repo/mongodb.keytab"
rm -f $keytab

if [ "$AUTH_MECHANISM" == "server" ]; then
  seed_data
  # Create princials
  # principal for mongod
  kadmin -r $REALM -p $ADMIN_USER/admin -w $ADMIN_PASSWORD addprinc -pw $pass mongodb/mongo.simagix.com
  kadmin -r $REALM -p $ADMIN_USER/admin -w $ADMIN_PASSWORD addprinc -pw $pass mdb
  printf "%b" "addent -password -p mongodb/mongo.simagix.com -k 1 -e aes256-cts\n$pass\naddent -password -p mdb -k 1 -e aes256-cts\n$pass\nwrite_kt $keytab" | ktutil

  # validate installation
  echo;echo "# mongoldap -f /etc/mongod.conf --user admin --password secret"
  mongoldap -f /etc/mongod.conf --user admin --password secret

  # Start mongod with auth and GSSAPI
  env KRB5_KTNAME=$keytab mongod -f /etc/mongod.conf

elif [ "$AUTH_MECHANISM" == "test" ]; then
  sleep 5
  printf "%b" "addent -password -p mongodb/test.simagix.com -k 1 -e aes256-cts\n$pass\naddent -password -p mdb -k 1 -e aes256-cts\n$pass\nwrite_kt $keytab" | ktutil
  klist -kt $keytab
  auth_scram
  auth_ldap
  auth_x509
  auth_gssapi

else
  exit 1
fi

# keep the instance up
touch /var/log/mongodb/mongod.log
tail -1f /var/log/mongodb/mongod.log
