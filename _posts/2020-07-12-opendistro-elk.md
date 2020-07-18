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
Follow steps from official guide at [opendistro install rpm](https://opendistro.github.io/for-elasticsearch-docs/docs/install/rpm/). (it's the source of truth)

### generate certificates
The easiest way is to follow official guide at [opendistro generate certificates](https://opendistro.github.io/for-elasticsearch-docs/docs/security/configuration/generate-certificates/).
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
DC = com
DC = example
O = Example Com Inc.
OU = Root CA
CN = Root CA
EOF
openssl req -new -config root-ca.cnf -key root-ca-key.pem -out root-ca.csr
cat <<EOF | tee root-ca.ext
basicConstraints = critical, CA:true
keyUsage = critical, digitalSignature,keyCertSign,cRLSign
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid
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
C = pl
L = test
O = client
OU = client
CN = admin
EOF
openssl req -new -config admin.cnf -key admin-key.pem -out admin.csr
cat <<EOF | tee admin.ext
authorityKeyIdentifier = keyid,issuer
subjectKeyIdentifier = hash
basicConstraints = critical, CA:false
keyUsage = critical, digitalSignature,keyEncipherment,nonRepudiation
extendedKeyUsage = critical, clientAuth
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
DC = pl
L = test
O = node
OU = node
CN = elasticmaster.example.com
EOF
openssl req -new -config elasticmaster.cnf -key elasticmaster-key.pem -out elasticmaster.csr
cat <<EOF | tee elasticmaster.ext
authorityKeyIdentifier = keyid,issuer
subjectKeyIdentifier = hash
basicConstraints = critical, CA:false
keyUsage = critical, digitalSignature,keyEncipherment,nonRepudiation
extendedKeyUsage = critical, clientAuth,serverAuth
subjectAltName = RID:1.2.3.4.5.5,DNS:elasticmaster.local,DNS:elasticmaster,IP:192.168.122.4,IP:127.0.0.1
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
DC = pl
L = test
O = node
OU = node
CN = elasticslave.example.com
EOF
openssl req -new -config elasticslave.cnf -key elasticslave-key.pem -out elasticslave.csr
cat <<EOF | tee elasticslave.ext
authorityKeyIdentifier = keyid,issuer
subjectKeyIdentifier = hash
basicConstraints = critical, CA:false
keyUsage = critical, digitalSignature,keyEncipherment,nonRepudiation
extendedKeyUsage = critical, clientAuth,serverAuth
subjectAltName = RID:1.2.3.4.5.5,DNS:elasticslave.local,DNS:elasticslave,IP:192.168.122.5,IP:127.0.0.1
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
cluster.name: example-cluster
node.name: elasticmaster
discovery.seed_hosts: ["192.168.122.5"]
cluster.initial_master_nodes: ["elasticmaster"]

gateway.recover_after_nodes: 2 # change this to 3 if you have more nodes, to 1 to debug

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
  - CN=admin,OU=client,O=client,L=test,C=pl

opendistro_security.audit.type: internal_elasticsearch
opendistro_security.enable_snapshot_restore_privilege: true
opendistro_security.check_snapshot_restore_write_privileges: true
opendistro_security.restapi.roles_enabled: ["all_access", "security_rest_api_access"]
cluster.routing.allocation.disk.threshold_enabled: false
node.max_local_storage_nodes: 3

```

This node is set to be coordinating, master, data and ingesting node.
Explanation can be found at [opendistro cluster](https://opendistro.github.io/for-elasticsearch-docs/docs/elasticsearch/cluster/). As more nodes join the cluster, roles should be divided.

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
network.host: ["127.0.0.1", "192.168.122.4"]
http.port: 9200
```

# elasticslave
Follow the same steps as for elasticmaster, but copy the following certificates from master:
- root-ca.pem
- elasticslave-key.pem
- elasticslave.pem

This node can be configured as data only node:
```
cluster.name: example-cluster
node.name: elasticslave
network.host: ["127.0.0.1", "192.168.122.5"]
discovery.seed_hosts: ["192.168.122.4"]
cluster.initial_master_nodes: ["elasticslave"]

node.data: true
node.master: false
node.ingest: false

gateway.recover_after_nodes: 2 # same as for master, increase if possible

# comment and replace Demo Configuration
opendistro_security.ssl.transport.pemcert_filepath: /etc/elasticsearch/cert/elasticslave.pem
opendistro_security.ssl.transport.pemkey_filepath: /etc/elasticsearch/cert/elasticslave-key.pem
opendistro_security.ssl.transport.pemtrustedcas_filepath: /etc/elasticsearch/cert/root-ca.pem
opendistro_security.ssl.transport.enforce_hostname_verification: true
opendistro_security.allow_unsafe_democertificates: false
opendistro_security.authcz.admin_dn:
  - CN=admin,OU=client,O=client,L=test,C=pl

node.max_local_storage_nodes: 3
```
Notice hostname verification. Hostnames in certificates should match at least
by being present in /etc/hosts.

Once both nodes are up, run admin script for users on master node again to verify you can propagate configuration.

Check status of nodes from master node:
```
curl -XGET https://192.168.122.4:9200/_cat/nodes?v -u admin:admin --insecure
```

You should get something like this:
```
ip            heap.percent ram.percent cpu load_1m load_5m load_15m node.role master name
192.168.122.4           15          89  24    2.18    1.70     0.95 dimr      *      elasticmaster
192.168.122.5           15          95  15    0.38    0.48     0.27 dr        -      elasticslave
```

# logstashkibana
tbw
