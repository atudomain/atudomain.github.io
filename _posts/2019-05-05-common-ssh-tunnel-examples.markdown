---
layout: post
title:  "Examples: Common ssh tunneling"
date:   2019-05-05 12:41:00 +0200
categories: jekyll update
---

Jumphost is a server which is connected to internal network as well as accessible from the outside. It can be connected by "ssh atudomain@public.adress -p 2244" in these examples.

It is recommended to block ports using firewall when access from other systems is not needed (so they can be accessed only at localhost, not at ip address in local network).

### Tunnel port of internal host to localhost using jumphost

{% highlight bash %}
ssh -L 8888:192.168.0.11:8080 atudomain@public.address -p 2244
{% endhighlight %}

Using ssh connection atudomain@public.address maps port 8080 of 192.168.0.11 host (which is accessible from public.address host) to localhost:8888.

Do not publish sensitive or unprotected connections via localhost that way, especially in publicly available networks.

### Forward localhost (or any local address) port to port on jumphost

{% highlight bash %}
ssh -R 4444:localhost:8080 atudomain@public.address -p 2244
{% endhighlight %}

Maps port 8080 of localhost so it is accessible as port 4444 on public.address.

That is probably not a good idea, as public.address is publicly available (unless this is what you want to achieve). To publish to internal network only, use other method.

### Create socks proxy via jumphost locally

{% highlight bash %}
ssh -D 6666 atudomain@public.address -p 2244
{% endhighlight %}

Creates a socks proxy which can be used at localhost:6666 with for example a web browser. All traffic through that proxy goes to public.address first. It is like a browser connects from public.address. Beware again, it publishes socks proxy in your local network under your local ip address.
