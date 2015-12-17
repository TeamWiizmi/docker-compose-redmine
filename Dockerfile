FROM redmine:latest

ENV REDMINE_VERSION 3.2.0
ENV REDMINE_DOWNLOAD_MD5 b1050c3a0e6effd5a704ef5003d9df06

RUN curl -fSL "http://www.redmine.org/releases/redmine-${REDMINE_VERSION}.tar.gz" -o redmine.tar.gz \
  && echo "$REDMINE_DOWNLOAD_MD5 redmine.tar.gz" | md5sum -c - \
  && tar -xvf redmine.tar.gz --strip-components=1 \
  && rm redmine.tar.gz files/delete.me log/delete.me \
  && mkdir -p tmp/pdf public/plugin_assets \
  && chown -R redmine:redmine ./

RUN buildDeps='\
    gcc \
    libmagickcore-dev \
    libmagickwand-dev \
    libmysqlclient-dev \
    libpq-dev \
    libsqlite3-dev \
    make \
    patch \
  ' \
  && set -ex \
  && apt-get update && apt-get install -y $buildDeps --no-install-recommends \
  && rm -rf /var/lib/apt/lists/* \
  && rm Gemfile.lock \
  && bundle install --without development test \
  && for adapter in mysql2 postgresql sqlite3; do \
    echo "$RAILS_ENV:" > ./config/database.yml; \
    echo "  adapter: $adapter" >> ./config/database.yml; \
    bundle install --without development test; \
  done \
  && rm ./config/database.yml \
  && apt-get purge -y --auto-remove $buildDeps

COPY ./conf/configuration.yml /usr/src/redmine/config