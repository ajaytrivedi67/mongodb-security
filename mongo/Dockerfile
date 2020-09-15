FROM centos:7
LABEL Ken Chen <ken.chen@simagix.com>

RUN yum install -y krb5-libs krb5-auth-dialog krb5-workstation
ADD kerberos/krb5.conf /etc/krb5.conf
ADD mongo/mongodb-enterprise.repo /etc/yum.repos.d/
RUN yum -y install mongodb-enterprise && \
    yum clean all && \
    mkdir -p /data/db && \
    chown -R mongod:mongod /data/db
RUN yum install -y openldap-clients nss-pam-ldapd
EXPOSE 27017

ADD certs/*.pem /
ADD mongo/admin.js /
ADD mongo/mongod.conf /etc/mongod.conf
ADD mongo/entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
