#! /bin/bash
# Copyright 2019-present Kuei-chun Chen. All rights reserved.
# Kerberos on Centos installation
# Run as root or using sudo
yum install -y krb5-server krb5-libs krb5-auth-dialog krb5-workstation
mv -f /etc/krb5.conf /etc/krb5.conf.orig

REALM=SIMAGIX.COM
DOMAIN_REALM=kerberos.simagix.com
ADMIN_USER=admin
ADMIN_PASSWORD=secret
MASTER_KEY=MASTER_KEY

cat > /etc/krb5.conf <<EOF
[logging]
   default = FILE:/var/log/kerberos/krb5libs.log
   kdc = FILE:/var/log/kerberos/krb5kdc.log
   admin_server = FILE:/var/log/kerberos/kadmind.log
[libdefaults]
   default_realm = SIMAGIX.COM
   dns_lookup_realm = false
   dns_lookup_kdc = false
   ticket_lifetime = 24h
   renew_lifetime = 7d
   forwardable = true
[realms]
   SIMAGIX.COM = {
      kdc = ${DOMAIN_REALM}
      admin_server = ${DOMAIN_REALM}
   }
[domain_realm]
   .${DOMAIN_REALM} = ${REALM}
   ${DOMAIN_REALM} = ${REALM}
EOF

# Create database
/usr/sbin/kdb5_util -P ${MASTER_KEY} -r ${REALM} create -s

# Create admin user and ACL
kadmin.local -q "addprinc -pw ${ADMIN_PASSWORD} ${ADMIN_USER}/admin"
mv /var/kerberos/krb5kdc/kadm5.acl /var/kerberos/krb5kdc/kadm5.acl.orig
echo "*/admin@${REALM} *" > /var/kerberos/krb5kdc/kadm5.acl

mkdir -p /var/log/kerberos
systemctl restart krb5kdc kadmin
systemctl enable krb5kdc kadmin
