FROM ubuntu:14.04
MAINTAINER mehdi me@edge.com

RUN locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

RUN dpkg-divert --local --rename --add /sbin/initctl
RUN ln -sf /bin/true /sbin/initctl

RUN echo "deb http://de.archive.ubuntu.com/ubuntu/ trusty main restricted universe multiverse\n deb http://de.archive.ubuntu.com/ubuntu/ trusty-updates main restricted universe multiverse\n deb http://security.ubuntu.com/ubuntu trusty-security main restricted universe multiverse" >> /etc/apt/sources.list.d/fcgi.list
RUN apt-get update
RUN apt-get -y upgrade

RUN DEBIAN_FRONTEND=noninteractive apt-get -y install apache2-mpm-worker libapache2-mod-fastcgi  python-setuptools curl git unzip vim-tiny

RUN DEBIAN_FRONTEND=noninteractive apt-get -y install php5 php5-cgi php5-curl php5-dev php5-json php5-redis php5-gd php5-mcrypt php5-memcache php5-memcached php5-mysqlnd php5-readline php5-fpm php5-mongo php5-oauth php5-odbc php5-gearman  php5-gd php5-intl php-pear php5-imagick php5-imap  php5-ming php5-ps php5-pspell php5-recode php5-tidy php5-xmlrpc php5-xsl


RUN echo "extension=mongo.so" > /etc/php5/mods-available/mongo.ini
RUN php5enmod mcrypt mongo

# php-fpm config
RUN sed -i -e "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g" /etc/php5/fpm/php.ini
RUN sed -i -e "s/upload_max_filesize\s*=\s*2M/upload_max_filesize = 100M/g" /etc/php5/fpm/php.ini
RUN sed -i -e "s/post_max_size\s*=\s*8M/post_max_size = 100M/g" /etc/php5/fpm/php.ini
RUN sed -i -e "s/;daemonize\s*=\s*yes/daemonize = no/g" /etc/php5/fpm/php-fpm.conf
RUN sed -i -e "s/;catch_workers_output\s*=\s*yes/catch_workers_output = yes/g" /etc/php5/fpm/pool.d/www.conf

RUN echo "listen=0.0.0.0:9000\n listen.owner = www-data\n listen.group = www-data\n pm = dynamic\n pm.max_children = 5\n pm.start_servers = 2\n pm.min_spare_servers = 1\n pm.max_spare_servers = 3" >> /etc/php5/fpm/pool.d/www.conf


RUN find /etc/php5/cli/conf.d/ -name "*.ini" -exec sed -i -re 's/^(\s*)#(.*)/\1;\2/g' {} \;

RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer


#apache config
ENV APACHE_RUN_USER www-data
ENV APACHE_RUN_GROUP www-data
ENV APACHE_LOG_DIR /var/log/apache2

# Configure /app folder with sample app
RUN mkdir -p /app && rm -fr /var/www && ln -s /app /var/www
ADD sample/ /app
RUN chown -R www-data:www-data /var/www/
RUN a2enmod rewrite headers actions fastcgi alias 


ADD phpfpm.sh /usr/local/bin/phpfpm.sh
ADD apache.sh /usr/local/bin/apache.sh
RUN chmod 755 /usr/local/bin/phpfpm.sh
RUN chmod 755 /usr/local/bin/apache.sh

ADD local-app.conf /etc/apache2/sites-enabled/000-default.conf

EXPOSE 80

ENTRYPOINT ["/usr/local/bin/phpfpm.sh"] 
ENTRYPOINT ["/usr/local/bin/apache.sh"] 
