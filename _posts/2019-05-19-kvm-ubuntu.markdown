---
layout: post
title:  "KVM on Ubuntu server"
date:   2019-05-19 12:40:00 +0200
categories: jekyll update
---

Virtualization is important part of production environments. Where comes convenience and simplicity, there often come serious limitations.

Therefore, tutorial on command-line qemu-kvm is present here. I used ubuntu 19.04 linux as a supervisor.

### I. Check system and install tools

First of all, Virtualization needs to be enabled on hardware. It should be loaded in kernel, enabled in BIOS and supported by processors. It is easy to find on web and most likely everything is enabled by default on modern systems.

Next, package qemu-kvm is essential software needed:

{% highlight bash %}
sudo apt install qemu-kvm
{% endhighlight %}

Install libvirt package that allows control of the virtualization processes:

{% highlight bash %}
sudo apt install libvirt-daemon-system
{% endhighlight %}

(Which should include libvirt-clients, if not - install it too.)

Notice new network interfaces:
- virbr0
- virbr0-nic

Check if libvirtd is running:

{% highlight bash %}
sudo systemctl status libvirtd
{% endhighlight %}

If not, start it at least.

Test virsh tool:

{% highlight bash %}
sudo virsh list
{% endhighlight %}

It should return empty board.

Note that installer probably added you to libvirt group and sudo is unnecessary using libvirt tools. However, I recommend using sudo for storing files in absolute locations on server.

Usage of libvirt is generally explained at libvirt wiki (https://wiki.libvirt.org/page/UbuntuKVMWalkthrough).

### II. Create virtual machine with virt-install

First, install tool for automated installation:

{% highlight bash %}
sudo apt install virtinst
{% endhighlight %}

Install lib for quering available os types - so virtualization can be tuned automatically:

{% highlight bash %}
sudo apt install libosinfo-bin
{% endhighlight %}

Run to get list of available os-variant:

{% highlight bash %}
sudo osinfo-query os
{% endhighlight %}

Important: Link '/var/lib/libvirt/images' directory to somewhere with enough free space to keep guest disks (ie. '/home/images', so only link is left in original location).

By default an interface is set up on virtual bridge virbr0, and the bridge is connected to one of interfaces that host uses. Virtual bridge subnet can be accessed by host. NAT is used to connect guest to the outside.

For graphical installation, following command can be used to start a virtual machine (in graphical environment Virt Viewer will be started; if DISPLAY variable is set for VNC, it will be used, also password for vnc and other details can be specified in '--graphics') (example for centos 7 iso):

{% highlight bash %}
sudo virt-install \
--name=centos7-vm \
--vcpus=1 \
--memory=1024 \
--cdrom=/tmp/isos/centos7.iso \
--disk size=10 \
--os-type=linux \
--os-variant=centos7.0
{% endhighlight %}

To reconnect with Virt Viewer:

{% highlight bash %}
sudo virt-viewer centos7-vm
{% endhighlight %}

VNC does not need to be installed separately. Just run with '--graphics vnc' (example for ubuntu 19.04 image):

{% highlight bash %}
sudo virt-install \
--name=ubuntu1904-vm \
--vcpus=1 \
--memory=1024 \
--cdrom=/tmp/isos/ubuntu1904.iso \
--disk size=10 \
--os-type=linux \
--os-variant=ubuntu19.04 \
--graphics vnc
{% endhighlight %}

Now, VNC display can be attached at localhost, probably at port 5900 (if not taken already). Create an SSH tunnel (ssh -L ...) and access it on your notebook with any VNC viewer.

If you insist on text-only local setup (Centos 7, for Ubuntu 19.04 does not work with local iso):

{% highlight bash %}
sudo virt-install \
--name=centos7-vm \
--vcpus=1 \
--memory=1024 \
--location=/tmp/isos/centos7.iso \
--disk size=10 \
--os-type=linux \
--os-variant=centos7.0 \
--graphics none \
--serial pty \
--extra-args 'console=ttyS0'
{% endhighlight %}

Consult virt-install manual for more options regarding vm configuration.

### IV. Create virtual machine manually

```
TODO
```

### V. Create network bridge

If you want to connect machines directly to the same subnet as your host, create network bridge on interface connected to the desired gateway.

Initial netplan config for enp1s0:

{% highlight yaml %}
network:
  ethernets:
    enp1s0:
      addresses:
      - 192.168.122.100/24
      gateway4: 192.168.122.1
      nameservers:
        addresses:
        - 8.8.8.8
        - 8.8.4.4
  version: 2
{% endhighlight %}

Bridge br0 on enp1s0:

{% highlight yaml %}
network:
  ethernets:
    enp1s0:
      dhcp4: no
      dhcp6: no
  bridges:
    br0:
      interfaces:
      - enp1s0
      addresses:
      - 192.168.122.100/24
      gateway4: 192.168.122.1
      nameservers:
        addresses:
        - 8.8.8.8
        - 8.8.4.4
  version: 2
{% endhighlight %}

You can create bridges on multiple interfaces and use different bridges on different guest machines - great solution for virtualization servers with advanced network cards, that need guests connected to the same network as host.

Relaod netplan and check it works:

{% highlight bash %}
sudo netplan apply
ip addr
{% endhighlight %}

Create virtual machine on bridge 'br0' by appending 'network':

{% highlight bash %}
sudo virt-install \
--name=ubuntu1904-vm \
--vcpus=1 \
--memory=1024 \
--cdrom=/tmp/isos/ubuntu1904.iso \
--disk size=10 \
--os-type=linux \
--os-variant=ubuntu19.04 \
--graphics vnc \
--network bridge=br0
{% endhighlight %}

That's it for now.
