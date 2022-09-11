#! /bin/bash
# Copyright 2019-present Kuei-chun Chen. All rights reserved.
: ${REALM:=EXAMPLE.COM}
: ${ADMIN_USER:=admin}
: ${ADMIN_PASSWORD:=secret}

AUTH_MECHANISM="$2"
mkdir -p /var/log/mongodb /var/log/kerberos

seed_data() {
  # create an admin user using localhost exception
  mongosh --quiet "mongodb://localhost/" --tls --tlsCAFile /ca.pem < /admin_user.js
  mongosh --quiet "mongodb://admin:secret@localhost/" --tls --tlsCAFile /ca.pem < /admin.js
}

# test scram login
auth_scram() {
  echo "==> SCRAM-SHA-256"
  mongosh --quiet "mongodb://admin:secret@mongo.simagix.com/?authSource=admin" \
    --tls --tlsCAFile /ca.pem --eval 'db.runCommand({connectionStatus : 1})'
}

auth_x509() {
  echo "==> MONGODB-X509"
  mongosh --quiet "mongodb://mongo.simagix.com/?authMechanism=MONGODB-X509&authSource=\$external" \
    --tls --tlsCAFile /ca.pem --tlsCertificateKeyFile /client.pem \
    --eval 'db.runCommand({connectionStatus : 1})'
}

# test LDAP
auth_ldap() {
  echo "==> PLAIN"
  # mdb user exists in $external database
  mongosh --quiet "mongodb://mdb:secret@mongo.simagix.com/?authMechanism=PLAIN&authSource=\$external" \
    --tls --tlsCAFile /ca.pem --eval 'db.runCommand({connectionStatus : 1})'
}

# test Kerberos
auth_gssapi() {
  echo "==> GSSAPI"
  # Use a connection string, %2f: / and %40: @
  kinit mdb@$REALM -kt $keytab
  mongosh --quiet "mongodb://mdb%40$REALM:xxx@mongo.simagix.com/?authMechanism=GSSAPI&authSource=\$external" \
    --tls --tlsCAFile /ca.pem --eval 'db.runCommand({connectionStatus : 1})'
}

# Enable TLS
echo "TLS_REQCERT never" >> /etc/openldap/ldap.conf
echo "TLS_CACERT /server.pem" >> /etc/openldap/ldap.conf
echo "127.0.0.1	localhost" > /etc/hosts
# necessary for Kerberos reverse DNS lookup
echo "$(ping -c 1 kerberos|head -1|cut -d'(' -f2|cut -d')' -f1)  kerberos.simagix.com kerberos" >> /etc/hosts
echo "$(ping -c 1 kmip|head -1|cut -d'(' -f2|cut -d')' -f1)  kmip.simagix.com kmip" >> /etc/hosts
echo "$(ping -c 1 ldap|head -1|cut -d'(' -f2|cut -d')' -f1)  ldap.simagix.com ldap" >> /etc/hosts
echo "$(ping -c 1 mongo|head -1|cut -d'(' -f2|cut -d')' -f1)  mongo.simagix.com mongo" >> /etc/hosts

pass="secret"
keytab="/mongodb.krb"
rm -f $keytab

if [ "$AUTH_MECHANISM" == "server" ]; then
  # Create princials
  # principal for mongod
  kadmin -r $REALM -p $ADMIN_USER/admin -w $ADMIN_PASSWORD addprinc -pw $pass mongodb/mongo.simagix.com
  kadmin -r $REALM -p $ADMIN_USER/admin -w $ADMIN_PASSWORD addprinc -pw $pass mdb
  printf "%b" "addent -password -p mongodb/mongo.simagix.com -k 1 -e aes256-cts\n$pass\naddent -password -p mdb -k 1 -e aes256-cts\n$pass\nwrite_kt $keytab" | ktutil

  # validate installation
  # echo;echo "# mongoldap -f /etc/mongod.conf --user admin --password $pass"
  # mongoldap -f /etc/mongod.conf --user admin --password $pass

  # Start mongod with auth and GSSAPI
  echo "$pass" > /secret
  chmod 600 /etc/mongod.conf
  sleep 5
  env KRB5_KTNAME=$keytab mongod -f /etc/mongod.conf --configExpand "exec"
  seed_data
elif [ "$AUTH_MECHANISM" == "client" ]; then
  sleep 10
  printf "%b" "addent -password -p mongodb/client.simagix.com -k 1 -e aes256-cts\n$pass\naddent -password -p mdb -k 1 -e aes256-cts\n$pass\nwrite_kt $keytab" | ktutil
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
tail -1f /var/log/mongodb/mongod.log | grep -v '"I"'
