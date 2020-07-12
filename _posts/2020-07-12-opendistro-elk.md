---
layout: post
label: devops
title:  "Centos 8: Opendistro ELK"
date:   2020-07-12 13:24:00 +0200
---

The setup consists of 3 servers:
- logstashkibana 192.168.122.3
- elasticmaster  192.168.122.4
- elasticslave   192.168.122.5
It can be extrapolated on more elasticsearch instances.

# elasticmaster

### install elsticsearch
Follow steps from official guide at https://opendistro.github.io/for-elasticsearch-docs/docs/install/rpm/. (it's the source of truth)

### generate certificates
The easiest way is to follow official guide at https://opendistro.github.io/for-elasticsearch-docs/docs/security/configuration/generate-certificates/.
It generates certificates for single hostname though.
I recommend setting alternative names for the certificates. Then, the procedure is:
- root CA (you could use CA already owned and skip this point):
```
openssl genrsa -out root-ca-key.pem 4096
cat <<EOF | tee root-ca.cnf
[req]
prompt = no
distinguished_name = dn
[dn]
CN = elasticmaster.local
emailAddress = admin@elasticmaster.local
O = Example Ltd
L = Poland
C = PL
EOF
openssl req -new -config root-ca.cnf -key root-ca-key.pem -out root-ca.csr
cat <<EOF | tee root-ca.ext
subjectAltName = DNS:elasticmaster.local,IP:192.168.122.4
keyUsage = keyCertSign,cRLSign
EOF
openssl x509 -req -days 3650 -in root-ca.csr -signkey root-ca-key.pem -extfile root-ca.ext -out root-ca.pem
rm -f root-ca.cnf root-ca.csr root-ca.ext
```
- admin certificate:
```
openssl genrsa -out admin-key-temp.pem 4096
openssl pkcs8 -inform PEM -outform PEM -in admin-key-temp.pem -topk8 -nocrypt -v1 PBE-SHA1-3DES -out admin-key.pem
cat <<EOF | tee admin.cnf
[req]
prompt = no
distinguished_name = dn
[dn]
CN = elasticmaster.local
emailAddress = admin@elasticmaster.local
O = Example Ltd
L = Poland
C = PL
EOF
openssl req -new -config admin.cnf -key admin-key.pem -out admin.csr
cat <<EOF | tee admin.ext
subjectAltName = DNS:elasticmaster.local,IP:192.168.122.4
EOF
openssl x509 -req -days 3650 -in admin.csr -CA root-ca.pem -CAkey root-ca-key.pem -extfile admin.ext -CAcreateserial -out admin.pem
rm -f admin-key-temp.pem admin.cnf admin.csr admin.ext root-ca.srl
```
- master node certificate:
```
openssl genrsa -out elasticmaster-key-temp.pem 4096
openssl pkcs8 -inform PEM -outform PEM -in elasticmaster-key-temp.pem -topk8 -nocrypt -v1 PBE-SHA1-3DES -out elasticmaster-key.pem
cat <<EOF | tee elasticmaster.cnf
[req]
prompt = no
distinguished_name = dn
[dn]
CN = elasticmaster.local
emailAddress = elasticmaster@elasticmaster.local
O = Example Ltd
L = Poland
C = PL
EOF
openssl req -new -config elasticmaster.cnf -key elasticmaster-key.pem -out elasticmaster.csr
cat <<EOF | tee elasticmaster.ext
subjectAltName = DNS:elasticmaster.local,IP:192.168.122.4
EOF
openssl x509 -req -days 3650 -in elasticmaster.csr -CA root-ca.pem -CAkey root-ca-key.pem -extfile elasticmaster.ext -CAcreateserial -out elasticmaster.pem
rm -f elasticmaster-key-temp.pem elasticmaster.cnf elasticmaster.csr elasticmaster.ext root-ca.srl
```
- slave node certificate:
```
openssl genrsa -out elasticslave-key-temp.pem 4096
openssl pkcs8 -inform PEM -outform PEM -in elasticslave-key-temp.pem -topk8 -nocrypt -v1 PBE-SHA1-3DES -out elasticslave-key.pem
cat <<EOF | tee elasticslave.cnf
[req]
prompt = no
distinguished_name = dn
[dn]
CN = elasticslave.local
emailAddress = admin@elasticslave.local
O = Example Ltd
L = Poland
C = PL
EOF
openssl req -new -config elasticslave.cnf -key elasticslave-key.pem -out elasticslave.csr
cat <<EOF | tee elasticslave.ext
subjectAltName = DNS:elasticslave.local,IP:192.168.122.4
EOF
openssl x509 -req -days 3650 -in elasticslave.csr -CA root-ca.pem -CAkey root-ca-key.pem -extfile elasticslave.ext -CAcreateserial -out elasticslave.pem
rm -f elasticslave-key-temp.pem elasticslave.cnf elasticslave.csr elasticslave.ext root-ca.srl
```
You should end up with the following keys and files:
- root-ca-key.pem
- root-ca.pem
- admin-key.pem
- admin.pem
- elasticmaster-key.pem
- elasticmaster.pem
- elasticslave-key.pem
- elasticslave.pem


### configure elesticsearch

# elasticslave
# logstashkibana
