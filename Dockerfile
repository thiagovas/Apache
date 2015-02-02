FROM htmlgraphic/base
MAINTAINER Jason Gegere <jason@htmlgraphic.com>

# Install packages then remove cache package list information
RUN apt-get update && apt-get -yq install \
        openssh-server \
        apache2 \
        libapache2-mod-php5 \
        php5-mcrypt \
        php5-mysql \
        php5-gd \
        php5-curl \
        php-pear \
        php-apc \
        aptitude && aptitude install apache2-suexec-pristine

RUN DEBIAN_FRONTEND=noninteractive apt-get update && apt-get -y install \
        supervisor \
        rsyslog \
        postfix && rm -rf /var/lib/apt/lists/*


# SUPERVISOR
RUN mkdir -p /var/lock/apache2 /var/run/apache2 /var/log/supervisor
ADD supervisord.conf /etc/supervisor/conf.d/

# POSTFIX
ADD ./postfix.sh /opt/postfix.sh
RUN chmod 755 /opt/postfix.sh && cp /etc/hostname /etc/mailname

# APACHE
RUN curl -sS https://getcomposer.org/installer | php && mv composer.phar /usr/local/bin/composer

# Prepping OpenSSH
RUN mkdir /var/run/sshd
RUN sed -i "s/#PasswordAuthentication yes/PasswordAuthentication no/" /etc/ssh/sshd_config
RUN sed -i "s/LogLevel INFO/LogLevel VERBOSE/" /etc/ssh/sshd_config

# Updating root user
RUN chmod 755 /root && mkdir -p /root/.ssh

# Clearing and setting authorized ssh keys
RUN echo 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCbKBlYPbK29pUUwtwRIIjwCtZNujOUb77qHIeohOMk+O8z0gEIgkUwVI3x91AlbhctgpQor3IIeFITwGgIKVo33WW64HI9Nfr2vGx9EAfl9CL9cfDj9M9u4EFOn8NkD/TQMH4d1Fslt59eyl4fSV62d98zJ8goJwrolXM5NlS3hss8FtXhN6bNM0V5nliPUrv/1//3ZoZ5p0inOI1xWNHcMEILGllG+yqaknH9yIk880WoCYZuR7q2ddE6mxrBeJFiyryW5nhsxmXfHnsDVGiLh1C3hltEXzZ0Bdj11jhJfgIcuKU1iUFZg3kKVjRAvrteBQA328s5+UJswV+NWFiH hosting@htmlgraphic.com' >> /root/.ssh/authorized_keys


# PEAR Package needed for a web app
RUN pear install HTML_QuickForm

# Enable Apache mods.
RUN a2enmod php5 && a2enmod suexec && a2enmod userdir && a2enmod rewrite && a2enmod ssl && php5enmod mcrypt
 


# Manually set the apache environment variables in order to get apache to work immediately.
ENV APACHE_RUN_USER www-data
ENV APACHE_RUN_GROUP www-data
ENV APACHE_LOG_DIR /var/log/apache2
ENV APACHE_LOCK_DIR /var/lock/apache2
ENV APACHE_PID_FILE /var/run/apache2.pid

# Add coming page to root apache dir
ADD ./apache-config.conf /opt/apache-config.conf

# Add coming page to root apache dir
ADD ./index.php /opt/temp.php

# Add self signed SHA256 cert
ADD ./ssl/ssl-cert-snakeoil.key /opt/ssl-cert-snakeoil.key
ADD ./ssl/ssl-cert-snakeoil.pem /opt/ssl-cert-snakeoil.pem

# Copy simple scripts to build
ADD ./run.sh /opt/run.sh
ADD ./postfix-local-setup.sh /opt/postfix-local-setup.sh
ADD ./mac-permissions.sh /opt/mac-permissions.sh
RUN chmod 755 /opt/*

# Add VOLUMEs to allow backup of config and databases
VOLUME  ["/data"]

# Note that EXPOSE only works for inter-container links. It doesn't make ports accessible from the host. To expose port(s) to the host, at runtime, use the -p flag.
EXPOSE 22
EXPOSE 80
EXPOSE 443


CMD ["/opt/run.sh"]