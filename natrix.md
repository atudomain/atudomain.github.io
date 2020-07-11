---
layout: default
title: Natrix
---
# Natrix

Fast, simple, secure.

## Python is enough

- No more wrapping your shell in groovy and calling python from shell.
- Write pipeline using python.
- Use shared python libraries.
- Get sh() and stage() functions shipped with distribution - this is so simple now.

## No more fuss with integration

- Can be called using command line.
```
natrix.py -a someagent -p somepipeline
```
- Can be used with web UI (under development).
- Can be used with API (under development).

## Security
- Supports RBAC and TLS (under development).
- Supports LDAP (under development).

## Pipeline example
Directory structure (pipelines can be grouped in subdirectories):
```

├── pipelines
│   └── subdirectory
│       └── example_pipeline
│           ├── main.py
│           └── resources
│               └── script.sh

```
main.py:
```
from natrix.pipeline import stage
from natrix.shell import sh

import re
import os

stage('run some shell commands')

sh('python3 --version')
files = [
   line.strip()
   for line
   in sh('ls -l').split('\n')
   if re.match('^-', line)
]
print(files)

stage('run some python commands')

print(os.listdir())

stage('call script included in resources')

sh('bash script.sh')


```
output:
```


==================================================
             run some shell commands              
==================================================


Python 3.6.8

total 4

-rw-r--r--. 1 centos centos 95 07-11 19:58 script.sh

['-rw-r--r--. 1 centos centos 95 07-11 19:58 script.sh']


==================================================
             run some python commands             
==================================================


['script.sh']


==================================================
        call script included in resources         
==================================================


executing script...

executing script...

done

```

## Development status
Link to github and documentation will be supplied as soon as first
version with web ui is released.
