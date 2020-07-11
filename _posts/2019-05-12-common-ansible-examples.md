---
layout: post
label: beginnings
title:  "Examples: Common Ansible usage"
date:   2019-05-12 16:48:00 +0200
---

Let's write down some common Ansible examples so ad-hoc tasks can be performed quickly. Note that examples need ssh keys exchanged with remote hosts and user 'user' configured on those servers that can sudo without a password (and 'user1', 'user2' etc).

### I. Direct commands

Execute command for comma-separated list of hosts as user 'user' (comma required at the end, equivalent to using -m shell module):

{% highlight bash %}
ansible all -i "192.168.0.99,192.168.33.100," -u user -a 'uptime'
{% endhighlight %}

Use yum module to install 'tree' program on centos 7 host:

{% highlight bash %}
ansible all -i "192.168.0.99,192.168.33.100," -u user -m yum -a 'name=tree state=present use_backend=yum' --become
{% endhighlight %}

Suppose we wanted different users for different hosts:

{% highlight bash %}
ansible all -i "user1@192.168.0.99,user2@192.168.33.100," -m shell -a 'whoami'
{% endhighlight %}

### II. Inventory file

Hosts and their users can be defined in 'hosts' file.

```
[centos7]
centos1 ansible_host=192.168.0.11 ansible_user=user1
centos2 ansible_host=192.168.0.12 ansible_user=user2

[ubuntu1904]
ubuntu1 ansible_host=192.168.0.13 ansible_user=user3
ubuntu2 ansible_host=192.168.0.14 ansible_user=user4

[ubuntu1904:vars]
ansible_python_interpreter=/usr/bin/python3

```

That file defines two groups of hosts: centos and ubuntu1904. Each host is defined as well, so there are centos1, centos2, ubuntu1 and ubuntu2 hosts available for usage with ansible now. It also sets interpreter to python3 for ubuntu1904 group.

Notice that the names are somewhat unfortunate - you are going to duplicate host and group name (centos7).

### III. Commands using inventory

For these examples ansible needs to be run in directory containing 'hosts' file created before.

Run command on 'ubuntu1904' group:

{% highlight bash %}
ansible ubuntu1904 -i hosts -m apt -a 'name=tree state=present' --become
{% endhighlight %}

Run command on 'centos1' host only:

{% highlight bash %}
ansible centos1 -i hosts -m shell -a 'echo hello'
{% endhighlight %}

Run command on subset of group:

{% highlight bash %}
ansible centos7 -i hosts -m shell -a 'echo hello' --limit centos1
{% endhighlight %}

Exclude 'centos1' in subset of group:

{% highlight bash %}
ansible centos7 -i hosts -m shell -a 'echo hello' --limit '!centos1'
{% endhighlight %}

Exclude 'centos1' in shorter form:

{% highlight bash %}
ansible 'centos7:!centos1' -i hosts -m shell -a 'echo hello'
{% endhighlight %}

### IV. Running playbooks

Create a playbook so it runs on ubuntu1904 group and installs 'tree', then installs 'htop' if previous task is successful ('playbook.yml' file):

{% highlight yml %}
---
- hosts: ubuntu1904
  become: true
  tasks:
  - name: Install tree on ubuntu
    apt:
      name: tree
      state: present
  - name: Install htop on ubuntu
    apt:
      name: htop
      state: present

{% endhighlight %}

Run the playbook in analogical way as command-line modules, but do not specify group, host and actions  (--limit option may be useful now):

{% highlight bash %}
ansible-playbook playbook.yml -i hosts
{% endhighlight %}

### V. Important tasks in playbooks

All is run on 'ubuntu1904' group for simplicity.

- Install program using apt (or ensure it is already present)

Install all openjdk-8-* packages:

{% highlight yml %}
---
- hosts: ubuntu1904
  become: true
  tasks:
  - name: Install all openjdk-8-* packages
    apt:
      name: openjdk-8-*
      state: present

{% endhighlight %}

- Use external variables

Print variables value using playbook 'playbook.yml':

{% highlight yml %}
---
- hosts: ubuntu1904
  become: false
  tasks:
  - name: Echo variable value
    shell: echo "{{ "{{ var1 " }}}} {{ "{{ var 2 " }}}}"

{% endhighlight %}

Execute it with variable values:

{% highlight bash %}
ansible-playbook playbook.yml -e 'var1=hello var2=world'
{% endhighlight %}

Variables can be defined in 'hosts' file too, for groups/hosts as seen before and for all (all is predefined group of all available hosts):

```
[all:vars]
var1=hello
var2=world

```

- Use internal variables

Use predefined variables to construct other variables or just to use their values. Very important variable is "{{ "{{ ansible_user " }}}}. It can be used to make path to home directory on each host as an example (but '~' works even better).

```
[all:vars]
var3="say hello to {{ "{{ ansible_user " }}}}"

```

- Copy file from from local template (path relative to ansible invocation):

{% highlight yml %}
---
- hosts: ubuntu1904
  become: false
  tasks:
  - name: Copy template to slave
    copy:
      src: template.txt
      dest: ~/template.txt
      owner: "{{ "{{ ansible_user " }}}}"
      group: "{{ "{{ ansible_user " }}}}"
      mode: 0644

{% endhighlight %}

- Copy file from local template with parameters

Put parameters into 'template.txt':

```
This file was copied to the home of {{ "{{ ansible_user " }}}}.
```

Run ('copy' was changed to 'template'):

{% highlight yml %}
---
- hosts: ubuntu1904
  become: false
  tasks:
  - name: Copy template to slave
    template:
      src: template.txt
      dest: ~/template.txt
      owner: "{{ "{{ ansible_user " }}}}"
      group: "{{ "{{ ansible_user " }}}}"
      mode: 0644

{% endhighlight %}

- Modify lines in file

Add line and create file if not exists:

{% highlight yml %}
---
- hosts: ubuntu1904
  become: false
  tasks:
  - name: Create line or file
    lineinfile:
      path: ~/.bashrc
      line: 'set -o vi'
      create: yes

{% endhighlight %}

Remove line:

{% highlight yml %}
---
- hosts: ubuntu1904
  become: false
  tasks:
  - name: Append lines to file if they not exist
    lineinfile:
      path: ~/.bashrc
      regexp: '^set -o vi'
      state: absent

{% endhighlight %}

Use 'state: present' to ensure that line exists (create).

Replace line (sed is not bad, be careful with lineinfile as it sometimes surprises - ignore ansible warnings):

{% highlight yml %}
---
- hosts: ubuntu1904
  become: true
  tasks:
  - name: Replace lines in file
    shell: 'sed -i "s/127.0.0.1/127.0.0.1 localhost/g" /etc/hosts'

{% endhighlight %}

- Other uses

Most of common tasks such as creating groups and users can be automated - check [documentation][documentation].

### VI. Simple loop

Install multiple packages wiht apt:

{% highlight yml %}
---
- hosts: ubuntu1904
  become: true
  tasks:
  - name: Install several packages
    apt:
      name: "{{ "{{ item " }}}}"
      state: present
    with_items:
      - tree
      - htop
      - iftop

{% endhighlight %}

Useful loop example for replacing (appending is easier) multiple lines in file:

{% highlight yml %}
---
- hosts: ubuntu1904
  become: true
  tasks:
  - name: Append lines to file if they not exist
    lineinfile:
    dest: /etc/hosts
    regexp: "{{ "{{ item.regexp " }}}}"
    line: "{{ "{{ item.line " }}}}"
  with_items:
    - { regexp: '^127\.0\.0\.1', line: '127.0.0.1 localhost' }
    - { regexp: '^192\.168\.0\.11', line: '192.168.0.21' }
    - { regexp: '^192\.168\.0\.12', line: '192.168.0.22' }

{% endhighlight %}

It is important that there are single not double quotes.

### VII. Roles

You can use roles to run multiple playbooks at a time.

Prepare directory structure for this example:
```
.
├── hosts
├── playbook-of-roles.yml
└── roles
    ├── role1
    │   ├── tasks
    │   │   └── main.yml
    │   └── templates
    └── role2
        ├── tasks
        │   └── main.yml
        └── templates
```

Put into 'playbook-of-roles.yml':

{% highlight yml %}
---
- hosts: ubuntu1904
  become: true
  roles:
    - role1
    - role2
- hosts: ubuntu1904
  become: false
  roles:
    - role1
    - role2

{% endhighlight %}

Put into './roles/role1/tasks/main.yml':

{% highlight yml %}
---
- name: Who are you?
  shell: whoami

{% endhighlight %}

Put into './roles/role1/tasks/main.yml':

{% highlight yml %}
---
- name: Where are you?
  shell: pwd

{% endhighlight %}

Execute with '-v' option for verbose output:

{% highlight bash %}
ansible-playbook playbook-of-roles.yml -i hosts -v
{% endhighlight %}

Run only one selected role from a playbook, that requires sudo:

{% highlight bash %}
ansible ubuntu1904 -i hosts -m include_role -a 'name=role1' --become
{% endhighlight %}

### BONUS: Easily connect ansible through jumphost

Put this to [all:vars]:

```
[all:vars]
ansible_ssh_common_args=‘-o ProxyCommand=“ssh -W %h:%p -q user@jumphost -p 22”’

```

Note blank line below the block of code

That is going to connect ansible to hostnames available at 'jumphost' server. Comment if not needed.

[ans_doc]: https://docs.ansible.com/ansible/latest/modules/lineinfile_module.html
[documentation]: https://docs.ansible.com/
