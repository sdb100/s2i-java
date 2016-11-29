# Starts with RHEL and adds Oracle Java from a local gzip download.
# Used to build a plain Java app or a fatjar using Maven. 

# docker build -t first-project/s2i-java .
# docker run -t -i first-project/s2i-java /bin/bash

FROM rhel7:latest

MAINTAINER Steve Bell <steve.bell@worldpay.com>

ENV MAVEN_VERSION 3.3.9

# Install Oracle J8 from local zip #############################
# Assumes the jvm is a tar.gz in the ./jvm directory ###########
# Remove this if building from a J8 base image #################
COPY ./jvm/*.gz /opt/jvm/
RUN cd /opt/jvm \
    && tar xf *.tar.gz \
    && mv jdk* jdk \
    && ln -s /opt/jvm/jdk/bin/java /bin/java \
    && rm /opt/jvm/*.tar.gz

ENV JAVA_HOME=/opt/jvm/jdk

# HOME in base image is /opt/app-root/src

# Set up directories ###########################################
RUN mkdir -p /opt/openshift && \
    mkdir -p /opt/app-root/source && chmod -R a+rwX /opt/app-root/source && \
    mkdir -p /opt/s2i/destination && chmod -R a+rwX /opt/s2i/destination && \
    mkdir -p /opt/app-root/src && chmod -R a+rwX /opt/app-root/src

# Install Maven ################################################
RUN (curl -0 http://www.eu.apache.org/dist/maven/maven-3/$MAVEN_VERSION/binaries/apache-maven-$MAVEN_VERSION-bin.tar.gz | \
    tar -zx -C /usr/local) && \
    mv /usr/local/apache-maven-$MAVEN_VERSION /usr/local/maven && \
    ln -sf /usr/local/maven/bin/mvn /usr/local/bin/mvn && \
    mkdir -p $HOME/.m2 && chmod -R a+rwX $HOME/.m2

ENV PATH=/opt/maven/bin/:$PATH

#################################################################
# ENV BUILDER_VERSION 1.0

# Label #########################################################
LABEL io.k8s.description="Platform for building Java (fatjar) applications with maven" \
      io.k8s.display-name="Java S2I builder 1.0" \
      io.openshift.expose-services="8080:http" \
      io.openshift.tags="builder,maven-3,java,microservices,fatjar" 

# TODO (optional): Copy the builder files into /opt/openshift
# COPY ./<builder_folder>/ /opt/openshift/
# COPY Additional files,configurations that we want to ship by default, like a default setting.xml
COPY ./contrib/settings.xml $HOME/.m2/
COPY ./sti/bin/ /usr/local/sti 
RUN chmod -R a+rwx /usr/local/sti


LABEL io.openshift.s2i.scripts-url=image:///usr/local/sti

RUN chown -R 1001:1001 /opt/openshift \
    && chown -R 1001:1001 /usr/local/sti 

# This default user is created in the openshift/base-centos7 image
USER 1001

# Set the default port for applications built using this image
EXPOSE 8080

# Set the default CMD for the image
# CMD ["java","-Djava.security.egd=file:/dev/./urandom","-jar","/opt/openshift/app.jar"]
CMD ["usage"]