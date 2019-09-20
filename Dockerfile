FROM openjdk:8-jdk

ARG user=jenkins
ARG group=jenkins
ARG uid=1000
ARG gid=1000
ARG JENKINS_AGENT_HOME=/home/$user

ENV JENKINS_AGENT_HOME $JENKINS_AGENT_HOME

RUN groupadd -g $gid $group \
    && useradd -d "$JENKINS_AGENT_HOME" -u "$uid" -g "$gid" -m -s /bin/bash "$user"
RUN chown -R $user:$group $JENKINS_AGENT_HOME

# setup SSH server
RUN apt-get update \
    && apt-get install --no-install-recommends -y openssh-server \
    && rm -rf /var/lib/apt/lists/*
RUN sed -i /etc/ssh/sshd_config \
        -e 's/#PermitRootLogin.*/PermitRootLogin no/' \
        -e 's/#RSAAuthentication.*/RSAAuthentication yes/'  \
        -e 's/#PasswordAuthentication.*/PasswordAuthentication no/' \
        -e 's/#SyslogFacility.*/SyslogFacility AUTH/' \
        -e 's/#LogLevel.*/LogLevel INFO/' && \
    mkdir /var/run/sshd

RUN apt-get update \
    && apt-get install --no-install-recommends -y autoconf \
      bison \
      build-essential \
      libssl1.0-dev \
      libyaml-dev \
      libreadline6-dev \
      zlib1g-dev \
      libncurses5-dev \
      libffi-dev \
      libgdbm3 \
      libgdbm-dev \
      xvfb libgtk-3-dev libnotify-dev libgconf-2-4 libnss3 libxss1 libasound2 \
    && rm -rf /var/lib/apt/lists/*


ARG NODE_MAJOR=10
ARG YARN_VERSION=1.13.0

# Add NodeJS to sources list
RUN curl -sL https://deb.nodesource.com/setup_$NODE_MAJOR.x | bash -

# Add Yarn to the sources list
RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - \
  && echo 'deb http://dl.yarnpkg.com/debian/ stable main' > /etc/apt/sources.list.d/yarn.list

RUN apt-get update -qq && DEBIAN_FRONTEND=noninteractive apt-get -yq dist-upgrade && \
  DEBIAN_FRONTEND=noninteractive apt-get install -yq --no-install-recommends \
    nodejs \
    yarn=$YARN_VERSION-1 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
    truncate -s 0 /var/log/*log

WORKDIR "${JENKINS_AGENT_HOME}"

COPY setup-sshd /usr/local/bin/setup-sshd

EXPOSE 22

ENTRYPOINT ["setup-sshd"]
