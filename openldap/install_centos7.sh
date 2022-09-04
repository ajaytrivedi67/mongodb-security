#! /bin/bash
# Copyright 2019-present Kuei-chun Chen. All rights reserved.
# OpenLdap on Centos installation
# Run as root or using sudo

yum -y install openldap compat-openldap openldap-clients openldap-servers openldap-servers-sql openldap-devel
systemctl status slapd
systemctl start slapd
systemctl enable slapd
ADMIN_PASSWORD=secret
olcRootPW=$(slappasswd -h {SSHA} -s $ADMIN_PASSWORD)
cp db.ldif hdb.ldif
echo "olcRootPW: ${olcRootPW}" >> hdb.ldif
ldapmodify -Y EXTERNAL -H ldapi:/// -f hdb.ldif
ldapmodify -Y EXTERNAL -H ldapi:/// -f monitor.ldif

chown ldap:ldap /var/lib/ldap/*
ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/cosine.ldif
ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/nis.ldif
ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/inetorgperson.ldif

ldapadd -Q -Y EXTERNAL -H ldapi:/// -f memberof_config.ldif
ldapadd -Q -Y EXTERNAL -H ldapi:/// -f refint.ldif

ldapadd -x -w $ADMIN_PASSWORD -D "cn=ldapadm,dc=simagix,dc=local" -H ldapi:/// -f base.ldif
ldapadd -x -w $ADMIN_PASSWORD -D "cn=ldapadm,dc=simagix,dc=local" -H ldapi:/// -f users.ldif

ldapsearch -x -LLL -H ldapi:/// -b cn=admin,ou=users,dc=simagix,dc=local
ldapsearch -x -LLL -H ldapi:/// -b cn=admin,ou=users,dc=simagix,dc=local memberOf
