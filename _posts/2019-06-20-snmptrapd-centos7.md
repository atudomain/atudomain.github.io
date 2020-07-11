---
layout: post
label: beginnings
title:  "Centos 7: Simple snmptrapd usage"
date:   2019-06-20 13:00:00 +0200
---

Simple settings for snmptrapd to allow Centos 7 system to receive SNMPv2 traps for example from UPS controller.

### I. Install snmptrapd service

snmptrapd.service can be found in net-snmp package:

{% highlight bash %}
sudo yum install net-snmp
{% endhighlight %}

Path of the config file is '/etc/snmp/snmptrapd.conf'.

### II. Receive traps

If you do not want any security put the following line into snmptrapd.conf:

```
disableAuthorization yes
```

Otherwise you can configure community or other security features.

Start and enable the service:

{% highlight bash %}
sudo systemctl enable snmptrapd
sudo systemctl start snmptrapd
{% endhighlight %}

Watch to test that traps are received:

{% highlight bash %}
sudo journalctl -f -u snmptrapd.service
{% endhighlight %}

