
FROM almalinux:8

ARG dssVersion

ENV DSS_VERSION="$dssVersion" \
    DSS_DATADIR="/home/dataiku/dss" \
    DSS_PORT=10000

# Dataiku account and data dir setup
RUN useradd dataiku \
    && mkdir -p /home/dataiku ${DSS_DATADIR} \
    && chown -Rh dataiku:dataiku /home/dataiku ${DSS_DATADIR}

COPY run.sh /home/dataiku/

RUN chown dataiku:dataiku /home/dataiku/run.sh

RUN yum install -y gcc openssl-devel bzip2-devel libffi-devel zlib-devel xz-devel \
    && yum install -y make \
    && cd /usr/src  \
    && curl -OsS https://www.python.org/ftp/python/3.7.11/Python-3.7.11.tgz \
    && tar xzf Python-3.7.11.tgz \
    && cd Python-3.7.11 \
    && ./configure --enable-optimizations \
    && make altinstall \
    && rm /usr/src/Python-3.7.11.tgz \
    && yum clean all

RUN yum install -y gcc openssl-devel bzip2-devel libffi-devel zlib-devel xz-devel \
    && yum install -y make \
    && cd /usr/src  \
    && curl -OsS https://www.python.org/ftp/python/3.10.12/Python-3.10.12.tgz \
    && tar xzf Python-3.10.12.tgz \
    && cd Python-3.10.12 \
    && ./configure --enable-optimizations \
    && make altinstall \
    && rm /usr/src/Python-3.10.12.tgz \
    && yum clean all

# System dependencies
RUN yum install -y \
        epel-release \
    && yum install -y --enablerepo=powertools \
        glibc-langpack-en \
        file \
        acl \
        expat \
        git \
        nginx \
        unzip \
        zip \
        ncurses-compat-libs \
        java-1.8.0-openjdk \
        python2 \
        python36 \
        freetype \
        libgfortran \
        libgomp \
        R-core-devel \
        libicu-devel \
        libcurl-devel \
        openssl-devel \
        libxml2-devel \
        npm \
        gtk3 \
        libXScrnSaver \
        alsa-lib \
        nss \
        mesa-libgbm \
        libX11-xcb \
        python2-devel \
        python36-devel \
    && yum clean all

RUN yum install -y epel-release \
    && yum install -y dnf

RUN dnf config-manager --add-repo https://developer.download.nvidia.com/compute/cuda/repos/rhel8/x86_64/cuda-rhel8.repo \
    && dnf clean all \
    && dnf -y module install nvidia-driver:latest-dkms \
    && dnf -y install cuda

# Download and extract DSS kit
RUN DSSKIT="dataiku-dss-$DSS_VERSION" \
    && cd /home/dataiku \
    && echo "+ Downloading kit" \
    && curl -OsS "https://cdn.downloads.dataiku.com/public/studio/$DSS_VERSION/$DSSKIT.tar.gz" \
    && echo "+ Extracting kit" \
    && tar xf "$DSSKIT.tar.gz" \
    && rm "$DSSKIT.tar.gz" \
    && "$DSSKIT"/scripts/install/installdir-postinstall.sh "$DSSKIT" \
    && (cd "$DSSKIT"/resources/graphics-export && npm install puppeteer@13.7.0 fs) \
    && chown -Rh dataiku:dataiku "$DSSKIT"

# Install required R packages
RUN mkdir -p /usr/local/lib/R/site-library \
    && R --slave --no-restore \
        -e "install.packages( \
            c('httr', 'RJSONIO', 'dplyr', 'curl', 'IRkernel', 'sparklyr', 'ggplot2', 'gtools', 'tidyr', \
            'rmarkdown', 'base64enc', 'filelock'), \
            '/usr/local/lib/R/site-library', \
            repos='https://cloud.r-project.org')"



# Entry point
WORKDIR /home/dataiku

USER dataiku

EXPOSE $DSS_PORT

CMD [ "/home/dataiku/run.sh" ]

