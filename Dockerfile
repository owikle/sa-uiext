FROM ubuntu:18.04

RUN apt update && \
    apt upgrade -y && \
    apt install -y \
        curl

# Create a non-root user
RUN apt install sudo
RUN echo "ubuntu ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
RUN useradd -m --groups sudo ubuntu
USER ubuntu
WORKDIR /home/ubuntu

# Install ImageMagick
RUN curl https://imagemagick.org/download/binaries/magick -O
RUN chmod +x magick
RUN sudo mv magick /usr/local/bin/

# Docker-specific stuff to make imagemagick appimage work
RUN sudo apt install -y \
     libx11-dev \
     libharfbuzz-dev \
     libfribidi-dev \
     libfontconfig1
RUN sudo mv /usr/local/bin/magick /usr/local/bin/_magick
RUN echo '_magick --appimage-extract-and-run $@' | sudo tee /usr/local/bin/magick
RUN sudo chmod a+x /usr/local/bin/magick

# Install Ghostscript
RUN curl -L https://github.com/ArtifexSoftware/ghostpdl-downloads/releases/download/gs952/ghostscript-9.52-linux-x86_64.tgz -O
RUN tar xf ghostscript-9.52-linux-x86_64.tgz
RUN sudo mv ghostscript-9.52-linux-x86_64/gs-952-linux-x86_64 /usr/local/bin/gs
RUN rm -rf ghostscript-9.52-linux-x86_64*

# Install Xpdf
RUN sudo apt install libfontconfig1
RUN curl https://xpdfreader-dl.s3.amazonaws.com/xpdf-tools-linux-4.02.tar.gz -O
RUN tar xf xpdf-tools-linux-4.02.tar.gz
RUN sudo mv xpdf-tools-linux-4.02/bin64/pdftotext /usr/local/bin/
RUN rm -rf xpdf-tools-linux-4.02*

# Install Ruby via RVM and bundler and jekyll gems.
# https://rvm.io/rvm/install#1-download-and-run-the-rvm-installation-script
RUN sudo apt install -y gnupg2

# do this thing for Docker: https://rvm.io/rvm/security#ipv6-issues
RUN mkdir ~/.gnupg && \
    chmod 700 ~/.gnupg && \
    echo "disable-ipv6" > ~/.gnupg/dirmngr.conf

RUN gpg2 --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB
RUN curl -sSL https://get.rvm.io | bash -s stable
WORKDIR /home/ubuntu/collectionbuilder
RUN sudo chown ubuntu:ubuntu .
COPY Gemfile .
RUN /bin/bash -c "source ~/.rvm/scripts/rvm && \
    rvm install 2.7.0 && \
    rvm use 2.7.0 && \
    gem install bundler -v 2.1.4 && \
    bundle install"

CMD ["/bin/bash", "--login"]
