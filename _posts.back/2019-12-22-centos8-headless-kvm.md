---
layout: post
label: beginnings
title:  "Centos 8: Setup and usage of headless QEMU/KVM server"
date:   2019-12-22 21:13:00 +0200
---

Centos 8 system may be used as an efficient and secure virtualization platform.
QEMU/KVM headless server can be installed there and then remotely connected with
Virtual Machine Manager application.

### I. Install QEMU/KVM on hypervisor

Check recommended solution first:

```bash
yum group info "Virtualization Host"
```

Install the group, it contains all necessary tools and some more,
but ensures everything is going to start smoothly:

```bash
sudo yum group install "Virtualization Host"
```

Install and enable libvirtd service which is a deamon providing
API for controlling virtualization capabilities.

Check its status with:

```bash
systemctl status libvirtd
```

Start it if not started.

You should already have virsh utility available:

```bash
virsh version
```

Optionally, get virt-install utility to simplify
installation of new machines from command line:

```bash
sudo yum install virt-install
```

### II. Access libvirtd remotely using VMM

Install Virtual Machine Manager (VMM) on another linux system which
has a graphical interface.

On Centos 8:

```bash
sudo yum install virt-manager
```

Access 'File' -> 'Add connection...' and choose 'Connect to remote host
over SSH'.

You will need to enable access to libvirtd to remote user if you do
not want to connect as root:

```bash
sudo usermod -aG libvirt $(whoami)
```

Also, use 'ssh-copy-id' to allow connection without password
before configuring VMM.

Put images on remote host in '/var/lib/libvirt/images' directory, which is
default location and they will be easily accessible there.

You should now be able to manage virtualization remotely.

It is worth noticing that machines can be easily migrated between hypervisors connected
to the same VMM.
