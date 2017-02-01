FROM centos:centos6
RUN yum install -y epel-release wget
RUN wget http://people.centos.org/tru/devtools-2/devtools-2.repo \
        -O /etc/yum.repos.d/devtools-2.repo
RUN yum install -y \
        cmake3 \
        devtoolset-2-gcc \
        devtoolset-2-gcc-c++ \
        devtoolset-2-gdb \
        devtoolset-2-binutils \
        devtoolset-2-elfutils \
        git \
        make \
        tar \
        chrpath \
        libtool
RUN yum install -y \
        libX11-devel \
        strace
RUN yum install -y unzip
RUN yum install -y libXt-devel
RUN ln -s /usr/bin/cmake3 /usr/bin/cmake
RUN groupadd -r -g $(id -g) ${USER} && useradd -r -g ${USER} -u $(id -u) ${USER}
ENV HOME /home/${USER}
RUN mkdir -p ${HOME}
RUN chown ${USER}:${USER} ${HOME}
USER ${USER}
CMD . /opt/rh/devtoolset-2/enable && ./build.sh
