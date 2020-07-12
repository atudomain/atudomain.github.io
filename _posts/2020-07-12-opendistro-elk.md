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
keyUsage = critical, keyCertSign,cRLSign
basicConstraints = critical, CA:true
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

You should end up with the following keys and certificates:
- root-ca-key.pem
- root-ca.pem
- admin-key.pem
- admin.pem
- elasticmaster-key.pem
- elasticmaster.pem
- elasticslave-key.pem
- elasticslave.pem


### configure elesticsearch
Put the following certificates into '/etc/elasticsearch/cert' directory:
- elasticmaster-key.pem
- elasticmaster.pem
- root-ca.pem

Run:
```
chown -R elasticsearch:elasticsearch /etc/elasticsearch/cert
chmod 550 /etc/elasticsearch/cert
```
Remove old certificates from elasticsearch directory (you have to do this).
Set the following settings in '/etc/elasticsearch/elasticsearch.yml':
```
node.name: node-1
discovery.seed_hosts: ["127.0.0.1", "192.168.122.5"]
cluster.initial_master_nodes: ["node-1"]

# comment and replace Demo Configuration
opendistro_security.ssl.transport.pemcert_filepath: /etc/elasticsearch/cert/elasticmaster.pem
opendistro_security.ssl.transport.pemkey_filepath: /etc/elasticsearch/cert/elasticmaster-key.pem
opendistro_security.ssl.transport.pemtrustedcas_filepath: /etc/elasticsearch/cert/root-ca.pem
opendistro_security.ssl.transport.enforce_hostname_verification: true
opendistro_security.ssl.http.enabled: true
opendistro_security.ssl.http.pemcert_filepath: /etc/elasticsearch/cert/elasticmaster.pem
opendistro_security.ssl.http.pemkey_filepath: /etc/elasticsearch/cert/elasticmaster-key.pem
opendistro_security.ssl.http.pemtrustedcas_filepath: /etc/elasticsearch/cert/root-ca.pem
opendistro_security.allow_unsafe_democertificates: false
opendistro_security.allow_default_init_securityindex: false
opendistro_security.authcz.admin_dn:
  - C=PL,L=Poland,O=Example Ltd,EMAILADDRESS=admin@elasticmaster.local,CN=elasticmaster.local

opendistro_security.audit.type: internal_elasticsearch
opendistro_security.enable_snapshot_restore_privilege: true
opendistro_security.check_snapshot_restore_write_privileges: true
opendistro_security.restapi.roles_enabled: ["all_access", "security_rest_api_access"]
cluster.routing.allocation.disk.threshold_enabled: false
node.max_local_storage_nodes: 3
```
Notice reverse order of authcz.admin_dn.

This node is set to be coordinating, master, data and ingesting node.
Explanation can be found here https://opendistro.github.io/for-elasticsearch-docs/docs/elasticsearch/cluster/. As more nodes join the cluster, roles should be divided.

You may also want to set up jdk options to improve performance, notably in
'/etc/elasticsearch/jvm.options'.

You can access this elasticsearch locally with admin:admin credentials at this moment.

# prepare user accounts
This ELK integrates with LDAP nicely. But for now, just override demo users.
Go to '/usr/share/elasticsearch/plugins/opendistro_security/securityconfig/internal_users.yml'.
Comment all unwanted users. By default demo users have passwords equal logins.

For users that you need, replace hashes with passwords. You can get hashes by running the following command:
```
bash /usr/share/elasticsearch/plugins/opendistro_security/tools/hash.sh
```

Run admin script to reload configuration. Refer to you location of admin certificate and key:
```
cd /usr/share/elasticsearch/plugins/opendistro_security/tools
./securityadmin.sh -cd ../securityconfig/ -icl -nhnv \
   -cacert /etc/elasticsearch/cert/root-ca.pem \
   -cert /root/cert/admin.pem \
   -key /root/cert/admin-key.pem
```

Once this is done, open external access to elasticsearch in '/etc/elasticsearch/elasticsearch.yml':
```
network.host: 0.0.0.0
http.port: 9200
```

# elasticslave
Follow the same steps as for elasticmaster, but copy the following certificates from master:
- root-ca.pem
- elasticslave-key.pem
- elasticslave.pem

This node can be configured as data only node:
```
node.name: node-2
discovery.seed_hosts: ["127.0.0.1", "192.168.122.4"]
cluster.initial_master_nodes: ["node-1"]

node.data: true
node.master: false
node.ingest: false
node.coordinating: false

# comment and replace Demo Configuration
...
```
tbw

# logstashkibana
tbw
