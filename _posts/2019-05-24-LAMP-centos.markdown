---
layout: post
title:  "LAMP stack on Centos 7"
date:   2019-05-24 09:02:00 +0200
categories: jekyll update
---

LAMP stack may consist of PHP 5.4.16, Apache 2.4.6 and MariaDB 5.5.60 (as on day of writing this). Let's create it on Centos 7.

### I. Install apache and php

First install apache web server. It is important it is installed before php:

{% highlight bash %}
sudo yum install httpd
{% endhighlight %}

Next, install php and php gd (for better files uploads etc.):

{% highlight bash %}
sudo yum install php
sudo yum install php-gd
{% endhighlight %}

'libphp5.so' library should be already present for httpd.

### II. Install MariaDB

You can use default installation on Centos 7 to get MariaDB 5:

{% highlight bash %}
sudo yum install mariadb-server
{% endhighlight %}

Start it and enable it:

{% highlight bash %}
sudo systemctl start mariadb
sudo systemctl enable mariadb
{% endhighlight %}

Use secure installation script on runnig mariadb by typing:

{% highlight bash %}
sudo mysql_secure_installation
{% endhighlight %}

Finish steps when prompted and Maria is ready. But support for php must be installed still:

{% highlight bash %}
sudo yum install php-mysql
{% endhighlight %}

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
