FROM centos:7
LABEL Ken Chen <ken.chen@simagix.com>
RUN yum -y install openldap compat-openldap openldap-clients openldap-servers openldap-servers-sql openldap-devel

ADD openldap/*.ldif /
ADD certs/ldap.simagix.com.pem /server.pem

EXPOSE 389 636
ADD openldap/entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
