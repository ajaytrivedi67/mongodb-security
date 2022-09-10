FROM python:3
LABEL Ken Chen <ken.chen@simagix.com>

RUN apt-get update && apt-get install -y iputils-ping
RUN pip3 install pykmip
EXPOSE 5696

# ADD certs/kmip.simagix.com.pem /kmip-server-cert.pem
# ADD certs/kmip.simagix.com.pem /kmip-server-key.pem
# ADD certs/ca.pem /kmip-ca.pem
ADD certs/server_certificate.pem /kmip-server-cert.pem
ADD certs/server_key.pem /kmip-server-key.pem
ADD certs/root_certificate.pem /kmip-ca.pem

ADD pykmip/server.conf /etc/pykmip/
ADD pykmip/entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
