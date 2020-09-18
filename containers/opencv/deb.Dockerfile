ARG PY_VER=3.7

FROM python:${PY_VER}-slim

ARG OPENCV_VERSION=latest
ARG CMAKE_VERSION=latest
ARG MAKE_PIP=0

WORKDIR /root
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH" \
    MAKE_PIP=${MAKE_PIP}
COPY files/download.sh /root/download.sh

RUN apt-get update && \
    apt-get upgrade -y && \
    echo 'apt: install deps' && \
    apt-get -y --no-install-recommends install \
        apt-utils build-essential curl file gfortran git libatlas-base-dev \
        libavcodec-dev libavformat-dev libjpeg-dev libpng-dev libswscale-dev \
        libv4l-dev libx264-dev libxvidcore-dev pkg-config && \
    echo 'pip: install deps' && \
    pip install --no-cache-dir numpy pillow && \
    /root/download.sh && \
    /tmp/cmake.sh --skip-license --prefix=/usr/local

COPY files/make-deb.sh /root/make.sh
CMD ["/root/make.sh"]
