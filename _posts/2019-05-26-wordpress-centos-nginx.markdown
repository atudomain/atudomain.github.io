---
layout: post
title:  "Centos 7: Wordpress on nginx"
date:   2019-05-26 16:53:00 +0200
categories: jekyll update
---

Why not to try nginx? Based on nice materials [there][there], but shorter and with updated versions of software. Check if newer versions are already present.

### I. Install nginx

Enable nginx repo for centos 7. Put this into '/etc/yum.repos.d/nginx.repo' file:

```
[nginx]
name=nginx repo
baseurl=http://nginx.org/packages/mainline/centos/7/$basearch/
gpgcheck=0
enabled=1
```

If you have epel repository enabled, you need to disable it for the time of installation (naming conflicts).

Install nginx from nginx repo:

{% highlight bash %}
sudo yum install nginx
{% endhighlight %}

Start and enable:
{% highlight bash %}
sudo systemctl start nginx
sudo systemctl enable nginx
{% endhighlight %}

### II. Install MariaDB

Install MariaDB as described [here][here2].

Create 'wordpressuser' and its empty database 'wordpress'.

### III. Install php-fpm

Install it from remi-repo as described [here][here]:

Customize php-fpm to run with nginx. Edit '/etc/php-fpm.d/www.conf' so it contains these key-value pairs:

```
user = nginx
group = nginx
listen = /run/php-fpm/www.sock
listen.owner = nginx
listen.group = nginx
```

Change the ownership of '/var/lib/php':

{% highlight bash %}
sudo chown -R root:nginx /var/lib/php
{% endhighlight %}

Enable and start php-fpm:

{% highlight bash %}
sudo systemctl start php-fpm
sudo systemctl enable php-fpm
{% endhighlight %}

### IV. Install Wordpress

Download latest Wordpress and extract it to '/var/www/html' directory:

{% highlight bash %}
cd /var/www/html
wget https://wordpress.org/latest.tar.gz
tar -xzvf latest.tar.gz
{% endhighlight %}

Set permissions:

{% highlight bash %}
sudo chown -R nginx: /var/www/html/wordpress
{% endhighlight %}

Assume you have ssl certificates in '/etc/ssl/cacerts' directory. More on generating self-signed certificates [there][there2].

For getting official certificates you can consult for example [there][there3].

Create server block, for example '/etc/nginx/conf.d/atudomain.com.conf' for 'www.atudomain.com' domain:

```
server {
    listen 80;
    server_name www.atudomain.com atudomain.com;

    include snippets/letsencrypt.conf;
    return 301 https://atudomain.com$request_uri;
}

server {
    listen 443 ssl http2;
    server_name www.atudomain.com;

    ssl_certificate /etc/ssl/cacerts/atudomain.crt;
    ssl_certificate_key /etc/ssl/cacerts/atudomain.key;
    ssl_trusted_certificate /etc/ssl/cacerts/atudomain-CA.pem;
    include snippets/ssl.conf;

    return 301 https://atudomain.com$request_uri;
}

server {
    listen 443 ssl http2;
    server_name atudomain.com;

    root /var/www/html/atudomain.com;
    index index.php;

    ssl_certificate /etc/ssl/cacerts/atudomain.crt;
    ssl_certificate_key /etc/ssl/cacerts/atudomain.key;
    ssl_trusted_certificate /etc/ssl/cacerts/atudomain-CA.pem;
    include snippets/ssl.conf;
    include snippets/letsencrypt.conf;

    access_log /var/log/nginx/atudomain.com.access.log;
    error_log /var/log/nginx/atudomain.com.error.log;

    location = /favicon.ico {
        log_not_found off;
        access_log off;
    }

    location = /robots.txt {
        allow all;
        log_not_found off;
        access_log off;
    }

    location / {
        try_files $uri $uri/ /index.php?$args;
    }

    location ~ \.php$ {
        try_files $uri =404;
        fastcgi_pass unix:/run/php-fpm/www.sock;
        fastcgi_index   index.php;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include fastcgi_params;
    }

    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
        expires max;
        log_not_found off;
    }

}
```

Finally, finish by accessing and configuring defined page.

[there]: https://linuxize.com/post/how-to-install-wordpress-with-nginx-on-centos-7/
[there2]: https://atudomain.github.io/jekyll/update/2019/04/28/generate-ssl-certificate.html
[there3]: https://linuxize.com/post/secure-nginx-with-let-s-encrypt-on-centos-7/
[here]: https://atudomain.github.io/jekyll/update/2019/05/26/php-centos7.html
[here2]: https://atudomain.github.io/jekyll/update/2019/05/26/mariadb-centos7.html
