---
layout: post
title:  "LAMP stack on Centos 7"
date:   2019-05-24 09:02:00 +0200
categories: jekyll update
---

Simplest possible LAMP on Centos 7.

### I. Install apache and php

First install apache web server. It is important it is installed before php:

{% highlight bash %}
sudo yum install httpd
{% endhighlight %}

Next, install php and php gd (gd for better files uploads etc.). You can find how to do it [here][here].

'libphp5.so' library should be already present for httpd.

### II. Install MariaDB

Install MariaDB as described [here][here2].

### III. Test php with apache

Create hello.php file in '/var/www/html':

```
<html>
<head>
  <title>PHP Test</title>
</head>
<body>
  <?php    
    phpinfo();
  ?>
</body>
</html>
```

Create hello.conf file in '/etc/httpd/conf.d':

```
<VirtualHost *:80>
        ServerName localhost
        DocumentRoot "/var/www/html"
</VirtualHost>
```

Start and enable 'httpd' service then access, reload configuration:

{% highlight bash %}
sudo systemctl start httpd
sudo systemctl enable httpd
sudo apachectl graceful
{% endhighlight %}

Access 'http://localhost:80/hello.php'.

[here]: https://atudomain.github.io/jekyll/update/2019/05/27/php-centos7.html
[here2]: https://atudomain.github.io/jekyll/update/2019/05/27/mariadb-centos7.html
