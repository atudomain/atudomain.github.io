---
layout: post
title:  "Generate ssl certificate and sign it as a CA"
date:   2019-04-28 12:07:00 +0200
categories: jekyll update
---
There is a nice tutorial for this on the web ([there][there]). However, I wanted to have this in simplified form to copy-paste it with a possibility of making my own comments and improvements.

Assume the local domain for the certificate is 'atudomain'.

### I. Create a local CA

Create no-passphrase private key:

{% highlight bash %}
openssl genrsa -out atudomain-CA.key 2048
{% endhighlight %}

Alternatively create passphrase key:

{% highlight bash %}
openssl genrsa -des3 -out atudomain-CA.key 2048
{% endhighlight %}

Generate the certificate:

{% highlight bash %}
openssl req -x509 -new -nodes -key atudomain-CA.key -sha256 -days 1825 -out atudomain-CA.pem
{% endhighlight %}

### II. Create a certificate for a domain and sign it

Create private key, create CSR and remember to set Common Name to 'atudomain':

{% highlight bash %}
openssl genrsa -out atudomain.key 2048
openssl req -new -key atudomain.key -out atudomain.csr
{% endhighlight %}

Create SAN extension file 'atudomain.ext':

```
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
subjectAltName = @alt_names

[alt_names]
DNS.1 = atudomain
DNS.2 = atudomain.local
```
Create the certificate:

{% highlight bash %}
openssl x509 -req -in atudomain.csr -CA atudomain-CA.pem \
-CAkey atudomain-CA.key -CAcreateserial \
-out atudomain.crt -days 1825 -sha256 -extfile atudomain.ext
{% endhighlight %}

### III. Create certificate bundle in .pem format

To create bundle in .pem format from created certificate and key, run:

{% highlight bash %}
cat atudomain.key > atudomain.pem
cat atudomain.crt >> atudomain.pem
{% endhighlight %}

Note, that 'atudomain.pem' contains certificate private key. Also, intermediate certificates should be appended to this file if exist.

[there]: https://deliciousbrains.com/ssl-certificate-authority-for-local-https-development/
