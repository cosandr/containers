FROM python:3.7-slim

ARG TF_VERSION=v1.15.3
ARG BAZEL_VERSION=0.29.1

RUN pip install -U pip six numpy wheel mock 'future>=0.17.1' && \
    pip install -U --no-deps keras_applications keras_preprocessing && \
    apt-get update && \
    apt-get upgrade -y && \
    echo 'apt: install deps' && \
    apt-get -y --no-install-recommends install build-essential git pkg-config zip zlib1g-dev unzip curl

COPY files/download.sh /root/download.sh

RUN /root/download.sh && \
    /tmp/bazel.sh

COPY files/make.sh /root/make.sh
CMD [ "bash" ]
