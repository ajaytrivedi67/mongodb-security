#! /bin/bash
# Copyright 2019-present Kuei-chun Chen. All rights reserved.
: ${REALM:=EXAMPLE.COM}
: ${ADMIN_USER:=admin}
: ${ADMIN_PASSWORD:=secret}

AUTH_MECHANISM="$2"
mkdir -p /var/log/mongodb /var/log/kerberos

# Enable TLS
echo "TLS_REQCERT never" >> /etc/openldap/ldap.conf
echo "TLS_CACERT /server.pem" >> /etc/openldap/ldap.conf
echo "127.0.0.1	localhost" > /etc/hosts
# necessary for Kerberos reverse DNS lookup
echo "$(ping -c 1 kerberos|head -1|cut -d'(' -f2|cut -d')' -f1)  kerberos.simagix.com kerberos" >> /etc/hosts
echo "$(ping -c 1 ldap|head -1|cut -d'(' -f2|cut -d')' -f1)  ldap.simagix.com ldap" >> /etc/hosts
echo "$(ping -c 1 mongo|head -1|cut -d'(' -f2|cut -d')' -f1)  mongo.simagix.com mongo" >> /etc/hosts

pass="secret"
keytab="/mongodb.krb"
rm -f $keytab

if [ "$AUTH_MECHANISM" == "labs" ]; then
  kadmin -r $REALM -p $ADMIN_USER/admin -w $ADMIN_PASSWORD addprinc -pw $pass mongodb/mongo.simagix.com
  kadmin -r $REALM -p $ADMIN_USER/admin -w $ADMIN_PASSWORD addprinc -pw $pass mdb
  printf "%b" "addent -password -p mongodb/mongo.simagix.com -k 1 -e aes256-cts\n$pass\naddent -password -p mdb -k 1 -e aes256-cts\n$pass\nwrite_kt $keytab" | ktutil
  echo "$pass" > /secret
  # mongod -f /etc/mongod.conf
else
  exit 1
fi

# keep the instance up
touch /var/log/mongodb/mongod.log
tail -1f /var/log/mongodb/mongod.log | grep -v '"I"'
