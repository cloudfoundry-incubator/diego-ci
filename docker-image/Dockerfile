FROM ubuntu:focal

MAINTAINER https://github.com/cloudfoundry/diego-ci

ARG GO_VERSION
ARG CREDHUB_CLI_VERSION
ARG BBL_VERSION
ARG HUB_CLI_VERSION

ENV HOME /root
ENV GOPATH /root/go
ENV PATH /root/go/bin:/usr/local/go/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

RUN mkdir -p $GOPATH

# install build dependencies
# - graphviz is for rendering heap w/ pprof
ARG DEBIAN_FRONTEND=noninteractive
ENV TZ="America/New_York"
RUN \
  apt-get update && \
  apt-get -y install \
    build-essential \
    curl \
    git \
    graphviz \
    htop \
    lsof \
    psmisc \
    python \
    strace \
    wget \
    mercurial \
    mysql-server \
    zip \
    autoconf \
    xfsprogs \
    dnsmasq \
    iptables \
    lsb-release \
    pkg-config \
    quota \
    sudo \
    uidmap \
    sudo \
  && \
  apt-get clean

# install Go
RUN \
  wget -qO- https://golang.org/dl/go${GO_VERSION}.linux-amd64.tar.gz | tar -C /usr/local -xzf -

# Install postgres
RUN \
  echo "deb http://apt.postgresql.org/pub/repos/apt/ $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list && \
  wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add - && \
  apt-get update && \
  apt-get -y install postgresql-9.4 && \
  apt-get clean && \
  sed -i 's/peer/trust/' /etc/postgresql/9.4/main/pg_hba.conf && \
  sed -i 's/md5/trust/' /etc/postgresql/9.4/main/pg_hba.conf && \
  sed -i 's/max_connections = 100/max_connections = 300/' /etc/postgresql/9.4/main/postgresql.conf

# Setup Diego Database and Users
RUN service mysql start && \
  mysql -e "CREATE USER 'diego'@'localhost' IDENTIFIED BY 'diego_password';" && \
  mysql -e "GRANT ALL PRIVILEGES ON \`diego\_%\`.* TO 'diego'@'localhost';" && \
  mysql -e "GRANT ALL PRIVILEGES ON \`routingapi\_%\`.* TO 'diego'@'localhost';"

RUN service postgresql start && \
  createdb -U postgres diego && \
  psql -h localhost -Upostgres -c "CREATE USER diego WITH createrole superuser password 'diego_pw';"

RUN \
  wget -q https://releases.hashicorp.com/consul/0.7.0/consul_0.7.0_linux_amd64.zip -P /tmp/ && \
  unzip /tmp/consul_0.7.0_linux_amd64.zip -d /usr/local/bin && \
  rm /tmp/consul_0.7.0_linux_amd64.zip

# install version 1.28 of tar
RUN \
  wget -q http://ftp.gnu.org/gnu/tar/tar-1.28.tar.gz -P /tmp/ && \
  cd /tmp && \
  tar xzf tar-1.28.tar.gz && \
  cd tar-1.28 && \
  export LDFLAGS=-static && \
  export FORCE_UNSAFE_CONFIGURE=1 && \
  ./configure && \
  make && \
  make install && \
  rm -f /bin/tar && \
  rm -rf /tmp/tar-1.28*

RUN cd /usr/local/bin && \
  wget https://s3.amazonaws.com/bosh-cli-artifacts/bosh-cli-2.0.42-linux-amd64 && \
  mv bosh-cli-2.0.42-linux-amd64 bosh && \
  chmod +x ./bosh

# install libseccomp (needed for garden-runc)
RUN \
  wget https://github.com/seccomp/libseccomp/releases/download/v2.3.1/libseccomp-2.3.1.tar.gz && \
  tar zxf libseccomp-2.3.1.tar.gz && \
  cd libseccomp-2.3.1/  && \
  ./configure && \
  make && \
  make install
# default rootfs for warden; used for non-Docker inigo tests
# ADD inigo-test-rootfs.tar /opt/inigo/rootfs

