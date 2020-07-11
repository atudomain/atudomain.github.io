---
layout: post
label: cybersec
title:  "Verify certificates with openssl"
date:   2020-07-11 23:33:00 +0200
---

# Read rsa private key in pem format
```
openssl rsa -in private-key.pem -text -noout
```

# Read csr in pem format
```
openssl req -text -in request.csr -noout
```

# Read x509 public certificate in pem format
```
openssl x509 -text -in self-signed.pem -noout
```
