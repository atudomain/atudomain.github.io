---
layout: post
label: cybersec
title:  "Verify and convert certificates with openssl"
date:   2020-07-11 23:33:00 +0200
---

Certificates happen to not work. This is useful then.

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
openssl x509 -text -in cert.pem -noout
```

# Convert pem certificate to der
```
openssl x509 -inform PEM -in cert.pem -outform DER -out cert.der
```

# Convert der certificate to pem
```
openssl x509 -inform DER -in cert.der -outform PEM -out cert.pem
```

# Convert pem to pkcs#7
```
openssl crl2pkcs7 -nocrl -out cert.p7b -certfile cert.pem [-certfile cert-chain.pem]
```

# Read certificate in pkcs#7 format
```
openssl pkcs7 -noout -text -print_certs -in cert.p7b
```
Must be pem-formatted.

# Convert pem key and certificates to pkcs#12 format
```
openssl pkcs12 -export -name "Certificate" -out cert.p12 -inkey cert-key.pem -in cert.pem [-certfile cert-chain.pem]
```
