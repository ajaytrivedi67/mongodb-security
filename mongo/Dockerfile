FROM centos:7
LABEL Ken Chen <ken.chen@simagix.com>

RUN yum install -y krb5-libs krb5-auth-dialog krb5-workstation openldap-clients nss-pam-ldapd
ADD kerberos/krb5.conf /etc/krb5.conf
ADD mongo/mongodb-enterprise.repo /etc/yum.repos.d/
RUN yum -y install mongodb-enterprise && \
    mkdir -p /data/db && chown -R mongod:mongod /data/db
EXPOSE 27017

ADD certs/ca.pem /
ADD certs/mongo.simagix.com.pem /
ADD certs/ldap.simagix.com.pem /server.pem

ADD mongo/mongodb-keyfile /
ADD mongo/entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
