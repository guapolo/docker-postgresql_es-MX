FROM phusion/baseimage:0.9.19


MAINTAINER Guapolo <pjruiz@gmail.com>


RUN groupadd -r postgres --gid=999 && useradd -r -g postgres --uid=999 postgres


# GOSU - https://github.com/tianon/gosu
ENV GOSU_VERSION 1.9
RUN set -x \
  && apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    wget \
  && rm -rf /var/lib/apt/lists/* \
  && dpkgArch="$(dpkg --print-architecture | awk -F- '{ print $NF }')" \
  && wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch" \
  && wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch.asc" \
  && export GNUPGHOME="$(mktemp -d)" \
  && gpg --keyserver ha.pool.sks-keyservers.net --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 \
  && gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu \
  && rm -r "$GNUPGHOME" /usr/local/bin/gosu.asc \
  && chmod +x /usr/local/bin/gosu \
  && gosu nobody true \
  && apt-get purge -y --auto-remove ca-certificates wget


# Locale settings for US and MX
RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    locales \
  && rm -rf /var/lib/apt/lists/* \
  && localedef -i es_MX -c -f UTF-8 -A /usr/share/locale/locale.alias es_MX.UTF-8
ENV LANG=es_MX.utf8 \
  LC_ALL=es_MX.utf8 \
  LANGUAGE=es_MX.utf8


# PostgreSQL install
ENV PG_MAJOR=9.5
ENV PG_BIN_PATH="/usr/lib/postgresql/$PG_MAJOR/bin" \
  PG_DATA_DIR="/var/lib/postgresql" \
  PG_USERNAME="postgres" \
  PG_PASSWORD="aSuperSecurePassword"
ENV PATH $PG_BIN_PATH:$PATH

# Change hkp://ha.pool.sks-keyservers.net:80 to ha.pool.sks-keyservers.net if GPG firewall port allowed.
RUN apt-key adv --keyserver hkp://ha.pool.sks-keyservers.net:80 --recv-keys B97B0AFCAA1A47F044F244A07FCC7D46ACCC4CF8 \
  && /bin/bash -c 'source /etc/lsb-release' \
  && /bin/bash -c echo "deb http://apt.postgresql.org/pub/repos/apt/ $DISTRIB_CODENAME-pgdg main" $PG_MAJOR > /etc/apt/sources.list.d/pgdg.list \
  && apt-get update \
  && apt-get install -y --no-install-recommends \
    postgresql-common \
  && sed -ri 's/#(create_main_cluster) .*$/\1 = false/' /etc/postgresql-common/createcluster.conf \
  && apt-get install -y \
    postgresql-$PG_MAJOR \
    postgresql-contrib-$PG_MAJOR


COPY initdb.sh /
RUN chmod +x /initdb.sh \
  && /initdb.sh


VOLUME $PG_DATA_DIR
EXPOSE 5432


RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*


CMD ["/sbin/my_init"]

## Falta configurar SSL
