#!/bin/sh

echo "[req]
default_bits  = 2048
distinguished_name = req_distinguished_name
req_extensions = req_ext
x509_extensions = v3_req
prompt = no

[req_distinguished_name]
countryName = Nextcloud
stateOrProvinceName = Nextcloud
localityName = Nextcloud
organizationName = Nextcloud
commonName = $IP: Nextcloud

[req_ext]
subjectAltName = @alt_names

[v3_req]
subjectAltName = @alt_names

[alt_names]
IP.1 = $local_ip
IP.2 = $external_ip
" > san.cnf

openssl req -x509 -nodes -days 730 -newkey rsa:2048 -keyout key.pem -out cert.pem -config san.cnf
rm san.cnf
