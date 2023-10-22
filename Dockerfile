FROM ubuntu:focal as BUILD_IMAGE

ENV DEBCONF_NONINTERACTIVE_SEEN=true \
    DEBIAN_FRONTEND=noninteractive \
    LC_ALL=C.UTF-8 \
    LANG=en_US.utf8 \
    TZ=America/Los_Angeles

RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* 

RUN ln -s /usr/bin/dpkg-split /usr/sbin/dpkg-split \
    && ln -s /usr/bin/dpkg-split /usr/local/sbin/dpkg-split \
    && ln -s /usr/bin/dpkg-deb /usr/local/sbin/dpkg-deb \
    && ln -s /usr/bin/dpkg-deb /usr/sbin/dpkg-deb \
    && ln -s /bin/rm /usr/sbin/rm \
    && ln -s /bin/rm /usr/local/sbin/rm \
    && ln -s /bin/tar /usr/sbin/tar \
    && ln -s /bin/tar /usr/local/sbin/tar 

RUN apt-get update \
    && apt install --assume-yes --no-install-recommends gnupg software-properties-common file

RUN add-apt-repository ppa:iconnor/zoneminder-1.34 \
    && apt update

RUN DEBIAN_FRONTEND=noninteractive apt-get install -y zoneminder \
    && a2enconf zoneminder \
    && a2enmod rewrite cgi \
    && apt-get clean \
    && rm -Rf /var/lib/apt/lists/* 

RUN set -x \
  && apt-get update \
  && apt-get install -y libjson-perl cpanminus build-essential \
  && cpanm --mirror http://cpan.metacpan.org --verbose install Net::WebSocket::Server Config::IniFiles Time::Piece LWP::Protocol::https Net::MQTT::Simple \
  && rm -Rf /root/.cpanm && apt-get remove -y --purge build-essential \
  && apt-get autoremove -y \
  && apt-get clean \
  && rm -Rf /var/lib/apt/lists/*

ADD https://github.com/sjiampojamarn/zmeventnotification.git /zmeventnotification
RUN cd /zmeventnotification \
  && ./install.sh --no-interactive --install-hook --install-es --install-config \
  && mkdir -p /var/lib/zmeventnotification/push/ \
  && chown www-data:www-data -R /var/lib/zmeventnotification/push/ \
  && rm -Rf /zmeventnotification

RUN apt-get update \
  && apt-get install wget \
  && apt-get clean \
  && rm -Rf /var/lib/apt/lists/* 

VOLUME ["/var/lib/mysql", "/var/cache/zoneminder/events", "/var/cache/zoneminder/images"]
RUN mkdir -p /var/cache/zoneminder/events \
    && mkdir -p /var/cache/zoneminder/images \
    && chown -R www-data:www-data /var/cache/zoneminder \
    && mkdir -p /var/log/zoneminder \
    && chown -R www-data:www-data /var/log/zoneminder \
    && mkdir -p /var/log/zm \
    && chown -R www-data:www-data /var/log/zm \
    && mkdir -p /var/run/mysqld \
    && chmod 755 /var/run/mysqld

EXPOSE 80/tcp
EXPOSE 443/tcp
EXPOSE 9000/tcp

ADD https://raw.githubusercontent.com/sjiampojamarn/zmdockerfiles/master/utils/entrypoint.sh /usr/local/bin/
RUN chmod 755 /usr/local/bin/entrypoint.sh 
ENTRYPOINT ["/bin/bash", "-c", "chown -R www-data:www-data /var/cache/zoneminder && /usr/local/bin/entrypoint.sh"]
