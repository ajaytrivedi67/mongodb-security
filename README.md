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
  - SCRAM-SHA-1
  - MONGODB-X509
  - GSSAPI
  - PLAIN
- Authorization runs against ldap.simagix.com

## 1. Commands
### 1.1. build
```
./build.sh
```

### 1.2. startup
```
docker-compose up
```

### 1.3. shutdown
```
docker-compose down
```

### 1.4. ldapsearch
```
ldapsearch -x cn=mdb -b dc=simagix,dc=local -H ldaps://ldap.simagix.com
```

### 1.5. mongoldap
```
mongoldap --config /etc/mongod.conf --user mdb@SIMAGIX.COM --password secret
```

## 2. Security Playpen
### 2.1. attach to the `mongodb-security_test_1` container

```
docker exec -it mongodb-security_test_1 /bin/bash
```

### 2.2. SCRAM-SHA-1
```
mongo "mongodb://admin:secret@mongo.simagix.com/?authSource=admin" \
  --ssl --sslCAFile /ca.crt --sslPEMKeyFile /client.pem
```

### 2.3. MONGODB-X509
```
export login="CN=ken.chen%40simagix.com,OU=Users,O=Simagix,L=Atlanta,ST=Georgia,C=US"
mongo "mongodb://$login:xxx@mongo.simagix.com/?authMechanism=MONGODB-X509&authSource=\$external" \
  --ssl --sslCAFile /ca.crt --sslPEMKeyFile /client.pem
```

### 2.4. PLAIN (LDAP)
```
mongo "mongodb://mdb:secret@mongo.simagix.com/?authMechanism=PLAIN&authSource=\$external" \
  --ssl --sslCAFile /ca.crt --sslPEMKeyFile /client.pem
```

### 2.5. GSSAPI (Kerberos)
```
kinit mdb@SIMAGIX.COM -kt /repo/mongodb.keytab
mongo "mongodb://mdb%40$REALM:xxx@mongo.simagix.com/?authMechanism=GSSAPI&authSource=\$external" \
  --ssl --sslCAFile /ca.pem --sslPEMKeyFile /client.pem
```

### 2.6 mongo connection status
```
db.runCommand({connectionStatus : 1})
```

## 3. Misc.
### 3.1. certificates creation
```
source certs.env
create_certs.sh ldap.simagix.com mongo.simagix.com

certs
├── ca.pem
├── certs.env
├── client.pem
├── ldap.simagix.com.pem
└── mongo.simagix.com.pem
```
For additional certificates, use [create_certs.sh](https://github.com/simagix/mongo-x509) to sign using *master-certs.pem*.

### 3.2. enable LDAP TLS
Lines added to */etc/openldap/ldap.conf* on both ldap.simagix.com and mongo.simagix.com.

```
TLS_CACERT /server.pem
TLS_REQCERT never # self-signed certs
```
