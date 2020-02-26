FROM ubuntu:18.04

ARG DEBIAN_FRONTEND=noninteractive

RUN apt update && \
    apt upgrade -y && \
    apt install -y \
    build-essential \
    ruby-full \
    ruby-dev \
    rubygems \
    git \
    wget \
    ghostscript \
    libgs-dev \
    awscli

WORKDIR /tmp/
RUN wget https://imagemagick.org/download/ImageMagick-7.0.9-26.tar.gz && \
    tar xf ImageMagick-7.0.9-26.tar.gz && \
    cd ImageMagick-7.0.9-26/ && \
    ./configure --with-gslib=yes && \
    make && \
    make install && \
    ldconfig && \
    cd .. && \
    rm -r ImageMagick-7.0.9-26*

RUN gem install \
    jekyll \
    bundler

WORKDIR /app
COPY . .

EXPOSE 4000

ENTRYPOINT ["jekyll"]
CMD ["s", "-H", "0.0.0.0"]
