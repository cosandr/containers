ARG UBUNTU_VERSION=18.04

FROM ubuntu:${UBUNTU_VERSION}

ARG TF_VERSION=v1.15.4
ENV TF_VERSION=${TF_VERSION}

RUN apt-get update && \
    apt-get upgrade -y && \
    echo -e '\t*** install git ***' && \
    DEBIAN_FRONTEND=noninteractive apt-get -qq install \
        apt-transport-https ca-certificates software-properties-common \
        build-essential git zip zlib1g-dev unzip curl

ARG PY_VER=3.7
ENV PATH="/opt/venv/bin:$PATH"
RUN echo "\t*** install Python ${PY_VER} ***" && \
    add-apt-repository -y ppa:deadsnakes/ppa && \
    apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get -y install \
        python${PY_VER} python${PY_VER}-dev python${PY_VER}-distutils \
        python${PY_VER}-venv && \
    python${PY_VER} -m venv /opt/venv && \
    pip install -U pip wheel setuptools

COPY src /src
# COPY files/tensorflow-1.15-cuda10.2-python3.8.diff /tmp/tensorflow-1.15-cuda10.2-python3.8.diff
COPY files/*.patch /tmp/
COPY files/prep_tf.sh /tmp/prep_tf.sh
RUN echo "\t*** prepare TF ${TF_VERSION} ***" && \
    /tmp/prep_tf.sh

RUN echo "\t*** install Bazel ***" && \
    /src/tensorflow/tools/ci_build/install/install_bazel.sh

ARG USE_TF_PIP=0
ENV USE_TF_PIP=${USE_TF_PIP}
COPY files/pip.sh /tmp/pip.sh
RUN echo '\t*** install PIP deps ***' && \
    /tmp/pip.sh

# Set up the master bazelrc configuration file.
COPY src/tensorflow/tools/ci_build/install/.bazelrc /etc/bazel.bazelrc

COPY files/make.sh /src/make.sh

WORKDIR /src
CMD [ "bash" ]
