#######################################################################################
# Docker -> tripR
#
#                    ##        .
#              ## ## ##       ==
#           ## ## ## ##      ===
#       /""""""""""""""""\___/ ===
#  ~~~ {~~ ~~~~ ~~~ ~~~~ ~~ ~ /  ===- ~~~
#       \______ o          __/
#         \    \        __/
#          \____\______/
#
# Component:    docker-base
# Author:       Pierre-Marie de Jaureguiberry <pierre.marie.de.jaureguiberry@gmail.com>
#######################################################################################

# sysctl config /etc/sysctl.com
#vm.swappiness = 0
#net.ipv4.tcp_max_syn_backlog = 40000
#net.core.somaxconn = 40000
#net.ipv4.tcp_sack = 1
#net.ipv4.tcp_window_scaling = 1
#net.ipv4.tcp_fin_timeout = 15
#net.ipv4.tcp_keepalive_intvl = 30
#net.ipv4.tcp_tw_reuse = 1
#net.ipv4.tcp_moderate_rcvbuf = 1

FROM phusion/baseimage:0.9.9
MAINTAINER Pierre-Marie de Jaureguiberry <pierre.marie.de.jaureguiberry@gmail.com>

# reduce output from debconf
ENV DEBIAN_FRONTEND noninteractive
ENV PATH /usr/local/rvm/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# Environmental variables
ENV RIAK_VERSION 1.4.8
ENV RIAK_SHORT_VERSION 1.4

# Install Riak
ADD http://s3.amazonaws.com/downloads.basho.com/riak/${RIAK_SHORT_VERSION}/${RIAK_VERSION}/ubuntu/precise/riak_${RIAK_VERSION}-1_amd64.deb /
RUN (cd / && dpkg -i "riak_${RIAK_VERSION}-1_amd64.deb")

# Setup the Riak service
RUN mkdir -p /etc/service/riak
ADD bin/riak.sh /etc/service/riak/run

# Setup automatic clustering
ADD bin/automatic_clustering.sh /etc/my_init.d/99_automatic_clustering.sh

# Tune Riak configuration settings for the container
RUN sed -i.bak 's/127.0.0.1/0.0.0.0/' /etc/riak/app.config && \
    sed -i.bak 's/{anti_entropy_concurrency, 2}/{anti_entropy_concurrency, 1}/' /etc/riak/app.config && \
    sed -i.bak 's/{map_js_vm_count, 8 }/{map_js_vm_count, 0 }/' /etc/riak/app.config && \
    sed -i.bak 's/{reduce_js_vm_count, 6 }/{reduce_js_vm_count, 0 }/' /etc/riak/app.config && \
    sed -i.bak 's/{hook_js_vm_count, 2 }/{hook_js_vm_count, 0 }/' /etc/riak/app.config && \
    sed -i.bak "s/##+zdbbl/+zdbbl/" /etc/riak/vm.args

# Make Riak's data and log directories volumes
VOLUME /var/lib/riak
VOLUME /var/log/riak

# Open ports for HTTP and Protocol Buffers
EXPOSE 8098 8087

# Enable insecure SSH key
# See: https://github.com/phusion/baseimage-docker#using_the_insecure_key_for_one_container_only
RUN /usr/sbin/enable_insecure_key

# Cleanup
RUN rm "/riak_${RIAK_VERSION}-1_amd64.deb"
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Leverage the baseimage-docker init system
CMD ["/sbin/my_init", "--quiet"]
