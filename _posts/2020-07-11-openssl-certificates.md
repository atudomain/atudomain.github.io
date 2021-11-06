---
layout: post
label: cybersec
title:  "Cheatsheet: Generate certificates with openssl"
date:   2020-07-11 22:51:00 +0200
---

In practice, three kinds of certificates can be used:
- self-signed
- signed by private CA
- signed by external or externally trusted CA

Further, certificates may differ based on their predefined usage, mainly:
- ssl communication (web servers)
- tls communication
- software signing
- signing other certificates

Some simple templates are presented below.

# Generate rsa private key
```
openssl genrsa -out private-key.pem 4096
```

# Generate CSR
Configuration for request ( request.cnf ):
```
[req]
prompt = no
distinguished_name = dn

[dn]
CN = example.com
emailAddress = admin@example.com
O = Example Ltd
L = Poland
C = PL
```
Generate Certificate Signing Request ( request.csr ):
```
openssl req -new -config request.cnf -key private-key.pem -out request.csr
```

# Generate self-signed certificate
Generate rsa private key ( private-key.pem ).

Generate CSR ( request.csr ).

Extensions file ( request.ext ):
```
subjectAltName = DNS:*.example.com,DNS:example.com,IP:192.168.0.2
```
Generate certificate ( self-signed.pem ):
```
openssl x509 -req -days 3650 -in request.csr -signkey private-key.pem -extfile request.ext -out self-signed.pem
```

# Generate self-signed CA certificate
Generate rsa private key ( ca-private-key.pem ).

Generate CSR ( ca-request.csr ).

Extensions file ( ca-request.ext ):
```
keyUsage = critical, keyCertSign,cRLSign
basicConstraints = critical, CA:true
```
Generate certificate ( ca-self-signed.pem ):
```
openssl x509 -req -days 3650 -in ca-request.csr -signkey ca-private-key.pem -extfile ca-request.ext -out ca-self-signed.pem
```

# Generate and sign TLS client certificate
Generate rsa private key ( client-private-key.pem ).

Generate CSR ( client-request.csr ).

Extensions file ( client-request.ext ):
```
subjectAltName = DNS:client.example.com,IP:192.168.0.3
keyUsage = digitalSignature,keyEncipherment,dataEncipherment
extendedKeyUsage = clientAuth
```
Have CA private key ( ca-private-key.pem ).

Have CA certificate ( ca-self-signed.pem  / ca.pem ).

Generate and sign certificate:
```
openssl x509 -req -days 3650 -in client-request.csr -CA ca-self-signed.pem -CAkey ca-private-key.pem -extfile client-request.ext -CAcreateserial -out client.pem
```

# Generate and sign TLS server certificate
Generate rsa private key ( server-private-key.pem ).

Generate CSR ( server-request.csr ).

Extensions file ( server-request.ext ):
```
subjectAltName = DNS:server.example.com,IP:192.168.0.4
keyUsage = digitalSignature,keyEncipherment,nonRepudiation
extendedKeyUsage = serverAuth
```
Have CA private key ( ca-private-key.pem ).

Have CA certificate ( ca-self-signed.pem  / ca.pem ).

Generate and sign certificate:
```
openssl x509 -req -days 3650 -in server-request.csr -CA ca-self-signed.pem -CAkey ca-private-key.pem -extfile server-request.ext -CAcreateserial -out server.pem
```

# Some advanced usage restrictions

For CA certificate:
```
basicConstraints = critical, CA:true
keyUsage = critical, digitalSignature,keyCertSign,cRLSign
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid,issuer
```
For TLS client only, without hostname:
```
authorityKeyIdentifier = keyid,issuer
subjectKeyIdentifier = hash
basicConstraints = critical, CA:false
keyUsage = critical, digitalSignature,keyEncipherment,nonRepudiation
extendedKeyUsage = critical, clientAuth
```
For TLS client and server:
```
authorityKeyIdentifier = keyid,issuer
subjectKeyIdentifier = hash
basicConstraints = critical, CA:false
keyUsage = critical, digitalSignature,keyEncipherment,nonRepudiation
extendedKeyUsage = critical, clientAuth,serverAuth
subjectAltName = RID:1.2.3.4.5.5,DNS:elasticmaster.local,DNS:elasticmaster,IP:192.168.122.4,IP:127.0.0.1
```
