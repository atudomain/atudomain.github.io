---
layout: post
title:  "Use mod_rewrite with VirtualHost in Apache"
date:   2019-05-05 15:40:00 +0200
categories: jekyll update
---

In this tutorial, two apache web servers are deployed in private network, apache-1 and apache-2. First of them redirects to the second with a rewrite rule at the same time. Query string is removed and anchor tag is kept in the example. Next, reverse proxy for complete browser url is presented. It is shown how to proxy or forward all traffic to port 80 on apache-1, not just a single page.

### I. Install docker service

Docker service is needed, install it for your linux distribution. For ubuntu 19.04:

{% highlight bash %}
sudo apt install docker.io
{% endhighlight %}

You may want to add yourself to docker group, so you don't need to use sudo. Start the service.

### II. Create private bridge network

Create 192.168.66.0/24 local network (or any other not reserved) which will be accessible from docker host only. Name it apache-proxing:

{% highlight bash %}
docker network create --subnet 192.168.66.0/24 apache-proxing
{% endhighlight %}

### III. Start two web servers in private network

Pull httpd image if it is not already present:

{% highlight bash %}
docker pull httpd
{% endhighlight %}

Create apache-1 and apache-2 containers attaching each to custom network apache-proxing (give them unique static ips):

{% highlight bash %}
docker create --network apache-proxing --name apache-1 --ip 192.168.66.11 httpd
docker create --network apache-proxing --name apache-2 --ip 192.168.66.12 httpd
{% endhighlight %}

Start containers and install vim (example for apache-1 container):

{% highlight bash %}
docker start apache-1
docker exec -it apache-1 /bin/bash
apt-get update
apt-get install vim
exit
{% endhighlight %}

### IV. Distinguish servers

It will be helpful to edit what is displayed by each server. For apache-1 container edit /usr/local/apache2/htdocs/index.html file:

{% highlight html %}
<html><body><h1>SERVER 1</h2></body></html>
{% endhighlight %}

For apache-2 container edit the same file so it is like:

{% highlight html %}
<html>
<body>
<script>
function getUrlParameter(name) {
name = name.replace(/[\[]/, '\\[').replace(/[\]]/, '\\]');
var regex = new RegExp('[\\?&]' + name + '=([^&#]*)');
var results = regex.exec(location.search);
return results === null ? '' : decodeURIComponent(results[1].replace(/\+/g, ' '));
};
</script>
<br/>
<script>
document.write(getUrlParameter('firstname'));
document.write('<br/>');
document.write(getUrlParameter('lastname'));
</script>
<br/>
<p>text</p>
<p>text</p>
<p>text</p>
<h5 id="example">Example headline</h5>
<p>text</p>
<p>text</p>
<p>text</p>
</body>
</html>
{% endhighlight %}

JavaScript function was borrowed from A-Frame VR toolkit.

Paste enough "<p>text</p>" to be able to test anchor in url (so scrolling makes sense).

Test apache-2 by writing in your browser:

{% highlight html %}
http://192.168.66.12/?firstname=adrian&lastname=adriansurname#example
{% endhighlight %}

Now the page should be loaded with Example headline at the top. After you scroll to top you should be able to see parameters passed in url.

### V. Redirect page and remove query string

Time to modify apache-1. Go to /usr/local/apache2/etc/httpd.conf and uncomment these lines:

{% highlight html %}
LoadModule rewrite_module modules/mod_rewrite.so
{% endhighlight %}

Run to restart apache gracefully:

{% highlight bash %}
apachectl graceful
{% endhighlight %}

It is very important to try to restart apache gracefully and to correct all errors. Otherwise you will be left with a container that cannot start.

Append to /usr/local/apache2/etc/httpd.conf to make redirect to apache-2 and get rid of query string:

{% highlight html %}
<VirtualHost *:80>
    ServerName                   192.168.66.11

    RewriteEngine On
    RewriteCond "%{QUERY_STRING}" "(.*)"
    RewriteRule "^/(.*)" "http://192.168.66.12/$1?" [R=permanent]

    CustomLog logs/virtual.log combined
    ErrorLog  logs/error_virtual.log
    LogLevel  warn
</VirtualHost>
{% endhighlight %}

Restart apache gracefully. You should be able to access the page from apache-2 using apache-1 address: 

{% highlight html %}
http://192.168.66.11/?firstname=adrian&lastname=adriansurname#example
{% endhighlight %}

Address will change to 192.168.66.12 in your browser bar and anchor will be kept. Query string will not be present and parameters will be empty.

### VI. Change redirection to reverse proxy

If you want reverse proxy, you need to enable two additional modules in /usr/local/apache2/etc/httpd.conf:

{% highlight html %}
LoadModule proxy_module modules/mod_proxy.so
LoadModule proxy_http_module modules/mod_proxy_http.so
{% endhighlight %}

Next, change previously appended VirtualHost section to the following (we will keep the query string this time):

{% highlight html %}
<VirtualHost *:80>
    ProxyRequests Off
    ServerName                   192.168.66.11

    RewriteEngine On
    RewriteRule "^/(.*)" "http://192.168.66.12/$1" [P]
    ProxyPass   "/"      "http://192.168.66.12/"

    CustomLog logs/virtual.log combined
    ErrorLog  logs/error_virtual.log
    LogLevel  warn
</VirtualHost>
{% endhighlight %}

After graceful restart, by using 192.168.66.11 url, the browser should now show the page from 192.168.66.12. Actually, all traffic is proxied through 192.168.66.11 in both ways so url address stays the same.
