# MongoDB Enterprise Security Integration
This project demos how MongoDB Enterprise server uses Kerberos for authentication and LDAP for authorization.  Examples include:

- Install and configure Kerberos 5 on CentOS 7
- Install and configure OpenLDAP on CentOS 7
  - Users and Group creations
  - Enable TLS
- Install and configure MongoDB Enterprise
  - Kerberos *keytab* files creation
  - Kerberos GSSAPI authentication
  - LDAP configurations
  - Transport encryption using x509 certificates
- Authentication Mechanism
  - GSSAPI runs against mongo-gssapi.simagix.com
  - PLAIN runs against mongo-plain.simagix.com
  - Default (SCRAM-SHA-1) runs against mongo.simagix.com
- Authorization runs against mongo-plain.simagix.com

## build
```
docker build -t simagix/kerberos -f Dockerfile-krb .
docker build -t simagix/openldap -f Dockerfile-ldap .
docker build -t simagix/mongo-kerberos -f Dockerfile-mdb .
```

## Startup
```
docker-compose up
```

## Shutdown
```
docker-compose down
```

## Test
### Search LDAP
```
ldapsearch -x cn=mdb -b dc=simagix,dc=local -H ldaps://ldap.simagix.com
```

### Validate /etc/mongod.conf
```
mongoldap --config /etc/mongod.conf --user mdb@SIMAGIX.COM --password secret
```

### Connection Test
SCRAM-SHA-1:

```
mongo "mongodb://admin:secret@mongo.simagix.com/?authSource=admin" \
  --ssl --sslCAFile /ca.crt --sslPEMKeyFile /client.pem
```

LDAP:

```
mongo "mongodb://mdb%40$REALM:secret@mongo-plain.simagix.com/?authMechanism=PLAIN&authSource=\$external" \
  --ssl --sslCAFile /ca.crt --sslPEMKeyFile /client.pem
```

Kerberos:

```
mongo "mongodb://mdb%40$REALM:xxx@mongo-gssapi.simagix.com/?authMechanism=GSSAPI&authSource=\$external" \
  --ssl --sslCAFile /ca.crt --sslPEMKeyFile /client.pem
```

Check connection status:
```
db.runCommand({connectionStatus : 1})
```

## x509 Certificates
### Certificate Creation
```
create_certs.sh ldap.simagix.com mongo.simagix.com \
  mongo-gssapi.simagix.com mongo-plain.simagix.com

certs
├── ca.crt
├── ca.pem
├── client.pem
├── ldap.simagix.com.pem
├── mongo-gssapi.simagix.com.pem
├── mongo-plain.simagix.com.pem
└── mongo.simagix.com.pem
```
For additional certificates, use `certs/ca.pem` to sign.

[create_certs.sh](https://github.com/simagix/mongodb-utils/blob/master/certificates/create_certs.sh)

### Enable LDAP TLS
Lines added to */etc/openldap/ldap.conf* on both ldap.simagix.com and mongo-gssapi.simagix.com.

```
TLS_CACERT /server.pem
TLS_REQCERT never # self-signed certs
```
