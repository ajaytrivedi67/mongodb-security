FROM centos:7
LABEL Ken Chen <ken.chen@simagix.com>
RUN yum install -y krb5-server krb5-libs krb5-auth-dialog krb5-workstation
ADD kerberos/krb5.conf /etc/krb5.conf

EXPOSE 88 749
ADD kerberos/entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
