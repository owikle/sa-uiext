FROM ubuntu:18.04

ARG DEBIAN_FRONTEND=noninteractive

RUN apt update && \
    apt upgrade -y && \
    apt install -y \
    awscli \
    build-essential \
    curl \
    ghostscript \
    git \
    libgs-dev \
    ruby-dev \
    ruby-full \
    rubygems \
    xpdf

WORKDIR /tmp/
RUN curl https://imagemagick.org/download/releases/ImageMagick-7.0.10-5.tar.gz -o ImageMagick-7.0.10-5.tar.gz && \
    tar xf ImageMagick-7.0.10-5.tar.gz && \
    cd ImageMagick-7.0.10-5/ && \
    ./configure --with-gslib=yes && \
    make && \
    make install && \
    ldconfig && \
    cd .. && \
    rm -r ImageMagick-7.0.10-5*

RUN apt install sudo
RUN echo "ubuntu ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
RUN useradd -m --groups sudo ubuntu
USER ubuntu

RUN sudo gem install \
    jekyll \
    bundler

# Install Elasticsearch

WORKDIR /home/ubuntu
# https://www.elastic.co/guide/en/elasticsearch/reference/current/targz.html#install-linux
RUN curl -O https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-7.6.2-linux-x86_64.tar.gz  && \
    curl -O https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-7.6.2-linux-x86_64.tar.gz.sha512 && \
    shasum -a 512 -c elasticsearch-7.6.2-linux-x86_64.tar.gz.sha512 && \
    tar -xzf elasticsearch-7.6.2-linux-x86_64.tar.gz && \
    rm elasticsearch-7.6.2-linux-x86_64.tar.gz && \
    echo "export PATH=$PATH:~/elasticsearch-7.6.2/bin" >> ~/.bashrc

# Configure elasticsearch

RUN printf "\
network.host: 0.0.0.0\n\
discovery.type: single-node\n\
http.cors.enabled: true\n\
http.cors.allow-origin: \"*\"\n\
" >> ~/elasticsearch-7.6.2/config/elasticsearch.yml

WORKDIR collectionbuilder

EXPOSE 4000
EXPOSE 9200

ENTRYPOINT ["jekyll"]
CMD ["s", "-H", "0.0.0.0"]
