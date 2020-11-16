FROM nvidia/cuda:10.0-cudnn7-devel-ubuntu16.04

# In the Ubuntu 16.04 images, cudnn is placed in system paths. Move them to
# /usr/local/cuda
RUN cp -P /usr/include/cudnn.h /usr/local/cuda/include && \
    cp -P /usr/lib/x86_64-linux-gnu/libcudnn* /usr/local/cuda/lib64

# Installs TensorRT, which is not included in NVIDIA Docker containers.
RUN apt-get update && \
    apt-get install nvinfer-runtime-trt-repo-ubuntu1604-5.0.2-ga-cuda10.0 && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        libnvinfer-dev=5.1.5-1+cuda10.0 \
        libnvinfer5=5.1.5-1+cuda10.0

# Link NCCL libray and header where the build script expects them.
RUN mkdir /usr/local/cuda/lib &&  \
    ln -s /usr/lib/x86_64-linux-gnu/libnccl.so.2 /usr/local/cuda/lib/libnccl.so.2 && \
    ln -s /usr/include/nccl.h /usr/local/cuda/include/nccl.h

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

COPY files/make-gpu.sh /src/make.sh

WORKDIR /src
CMD [ "bash" ]
