#! /bin/bash
# Copyright 2019-present Kuei-chun Chen. All rights reserved.
: ${REALM:=EXAMPLE.COM}
: ${MASTER_KEY:=MASTER_KEY}
: ${ADMIN_USER:=admin}
: ${ADMIN_PASSWORD:=admin}

echo "127.0.0.1	localhost" > /etc/hosts
echo "$(ping -c 1 kerberos|head -1|cut -d'(' -f2|cut -d')' -f1)  kerberos.simagix.com kerberos" >> /etc/hosts

# Create database
/usr/sbin/kdb5_util -P $MASTER_KEY -r $REALM create -s

# Create admin user and ACL
kadmin.local -q "addprinc -pw $ADMIN_PASSWORD $ADMIN_USER/admin"
echo "*/admin@$REALM *" > /var/kerberos/krb5kdc/kadm5.acl

# Start Kerberos 5 KDC servers
mkdir -p /var/log/kerberos
/usr/sbin/krb5kdc -P /var/run/krb5kdc.pid
/usr/sbin/_kadmind -P /var/run/kadmind.pid
tail -1f /var/log/kerberos/krb5kdc.log
