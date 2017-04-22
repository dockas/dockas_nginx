FROM alpine:edge
MAINTAINER Dockas Dev Team <dev@dockas.com>

# Install dev dependencies
RUN build_pkgs="build-base git libffi-dev linux-headers python-dev openssl-dev" && \
    run_pkgs="logrotate dialog ca-certificates rsyslog openssl pcre zlib python bash augeas-libs supervisor nginx certbot apache2-utils" && \
    apk --update add ${build_pkgs} ${run_pkgs}

# Download and install consul-template
RUN mkdir -p /tmp && \
    wget -q -O /tmp/consul-template.zip https://releases.hashicorp.com/consul-template/0.15.0/consul-template_0.15.0_linux_amd64.zip && \
    unzip /tmp/consul-template.zip -d /usr/bin

# Download and install beats from elastic.co to forward nginx access log to logstash
# See https://github.com/rxwen/docker-filebeat/blob/master/Dockerfile
RUN mkdir -p /var/log/filebeat && \
    mkdir /lib64 && ln -s /lib/libc.musl-x86_64.so.1 /lib64/ld-linux-x86-64.so.2 && \
    wget -q -O /tmp/filebeat.tar.gz https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-5.0.1-linux-x86_64.tar.gz && \
    tar -xzf /tmp/filebeat.tar.gz && \
    cd filebeat-* && \
    cp filebeat /bin && \
    rm -rf /tmp/filebeat*

# and generate strong Diffie-Hellman group
# See https://www.digitalocean.com/community/tutorials/how-to-secure-nginx-with-let-s-encrypt-on-ubuntu-14-04
RUN openssl dhparam -out /etc/ssl/certs/dhparam.pem 2048 && \
    mkdir -p /home/ssl

# Set working directory
WORKDIR /home

# Add files
ADD conf ./conf
ADD servers ./servers
ADD start.sh ./
ADD supervisord.conf /etc/supervisord.conf
ADD logrotate.conf /etc/logrotate.conf
ADD logrotate.d/* /etc/logrotate.d/

# Make scripts executables
RUN chmod u+x start.sh && \
    touch /var/log/messages

# Create auth user
RUN htpasswd -b -c /home/conf/.htpasswd dockas Dockas*8 && \
    apk del ${build_pkgs}

# Environment variables
ENV LOGSTASH_HOSTS 'logstash-beats-lb.service.consul:10000'

# The main entrypoint
CMD ["/home/start.sh"]
