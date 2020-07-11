---
layout: post
label: beginnings
title:  "Centos 7: MariaDB"
date:   2019-05-26 21:08:00 +0200
---

Reference tutorial for MariaDB.

### I. Install MariaDB using default centos repository

You can use default installation on Centos 7 to get MariaDB 5:

{% highlight bash %}
sudo yum install mariadb-server
{% endhighlight %}

Support for php must be installed too if needed:

{% highlight bash %}
sudo yum install php-mysql
{% endhighlight %}

### II. Install MariaDB using official MariaDB repository

Enable maria repo by creating file '/etc/yum.repos.d/MariaDB.repo' (choose from available versions - visit [mariaDB site][mariasite]):

```
[mariadb]
name=MariaDB
baseurl=http://yum.mariadb.org/10.3/centos7-amd64
gpgkey=https://yum.mariadb.org/RPM-GPG-KEY-MariaDB
gpgcheck=1
```

Install MariaDB:

{% highlight bash %}
sudo yum install MariaDB-server MariaDB-client
{% endhighlight %}

### III. Start, enable and configure the server

Start MariaDB and enable it:

{% highlight bash %}
sudo systemctl start mariadb
sudo systemctl enable mariadb
{% endhighlight %}

Use secure installation script on running mariadb by typing:

{% highlight bash %}
sudo mysql_secure_installation
{% endhighlight %}

To connect, use:

{% highlight bash %}
mysql -u root -p
{% endhighlight %}

[mariasite]: https://downloads.mariadb.org/mariadb/repositories/#mirror=icm&distro=CentOS
