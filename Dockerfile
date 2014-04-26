FROM ubuntu:12.04

RUN apt-get update
RUN apt-get install -y git-core
RUN apt-get install -y pkg-config
RUN apt-get install -y libtool
RUN apt-get install -y autoconf
RUN apt-get install -y leiningen libzmq-dev
RUN apt-get install -y wget
RUN apt-get install -y make
RUN apt-get install -y maven
RUN apt-get install -y g++
RUN apt-get install -y zip unzip
RUN apt-get install -y ruby1.9.3
RUN gem install -r fpm

# ------------------------------------------------------------------------------------------------
# Oracle JDK installation
# ------------------------------------------------------------------------------------------------

ENV JDK_VER_AND_UPD 7u45
ENV JDK_TARBALL jdk-7u45-linux-x64.tar.gz
RUN mkdir -p ~/build
RUN wget --no-check-certificate --no-cookies \
  --header "Cookie: oraclelicense=accept-securebackup-cookie" \
  http://download.oracle.com/otn-pub/java/jdk/7u45-b18/${JDK_TARBALL} \
  -q -O ~/build/"${JDK_TARBALL}"
RUN mkdir -p /usr/lib/jvm && cd /usr/lib/jvm && tar xzf ~/build/"${JDK_TARBALL}"
RUN unlink /usr/lib/jvm/default-java
RUN cd /usr/lib/jvm && ln -s jdk1.7.0_45 default-java
ENV JAVA_HOME /usr/lib/jvm/default-java
RUN $JAVA_HOME/bin/java -version

# ------------------------------------------------------------------------------------------------
# jzmq
# ------------------------------------------------------------------------------------------------

RUN cd ~/build && git clone https://github.com/nathanmarz/jzmq.git

RUN cd ~/build/jzmq && ./autogen.sh && ./configure

# This will download the dependencies, just in case the next step fails.
RUN cd ~/build/jzmq && mvn dependency:tree

# No tests for now.
RUN cd ~/build/jzmq && mvn -DskipTests package

# Not sure why these two things are required, but the build does not work without them.
RUN cd ~/build/jzmq && touch src/classdist_noinst.stamp 
RUN cd ~/build/jzmq && rsync -az target/classes/ src

RUN cd ~/build/jzmq && make
RUN cd ~/build/jzmq && make install

# Run the tests this time.
RUN cd ~/build/jzmq && mvn package

# ------------------------------------------------------------------------------------------------
# Carbonite
# ------------------------------------------------------------------------------------------------

RUN cd ~/build && git clone https://github.com/clearstorydata/carbonite.git ~/build/carbonite
RUN cd ~/build/carbonite && git checkout 1.5.0-csd
RUN cd ~/build/carbonite && PATH=${JAVA_HOME}/bin:${PATH} bin/to_maven.sh install

# ------------------------------------------------------------------------------------------------
# Storm
# ------------------------------------------------------------------------------------------------

RUN cd ~/build && git clone https://github.com/clearstorydata/storm.git
RUN cd ~/build/storm && git checkout 0.8.2-csd
RUN cd ~/build/storm && PATH=${JAVA_HOME}/bin:${PATH} bash bin/to_maven.sh install
RUN cd ~/build/storm && PATH=${JAVA_HOME}/bin:${PATH} bash bin/build_release.sh install

# Debian packaging for Storm

RUN cd ~/build && git clone https://github.com/clearstorydata/storm-deb-packaging.git

