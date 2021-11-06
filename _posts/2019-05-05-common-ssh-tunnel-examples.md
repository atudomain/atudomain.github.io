---
layout: post
label: beginnings
title:  "Cheatsheet: Common ssh tunneling"
date:   2019-05-05 12:41:00 +0200
---

Jumphost is a server which is connected to internal network as well as accessible from the outside. It can be connected by "ssh atudomain@public.adress -p 2244" in these examples.

### Tunnel port of internal host to localhost using jumphost

{% highlight bash %}
ssh -L 8888:192.168.0.11:8080 atudomain@public.address -p 2244
{% endhighlight %}

Using ssh connection atudomain@public.address maps port 8080 of 192.168.0.11 host (which is accessible from public.address host) to 127.0.0.1:8888.

### Forward localhost (or any local address) port to port on jumphost

{% highlight bash %}
ssh -R 4444:localhost:8080 atudomain@public.address -p 2244
{% endhighlight %}

Maps port 8080 of localhost so it is accessible as port 4444 on public.address.

### Create socks proxy via jumphost locally

{% highlight bash %}
ssh -D 6666 atudomain@public.address -p 2244
{% endhighlight %}

Creates a socks proxy which can be used at 127.0.0.1:6666 with for example a web browser. All traffic through that proxy goes to public.address first. It is like a browser connects from 'public.address'.
