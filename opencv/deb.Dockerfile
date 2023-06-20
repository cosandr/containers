ARG PY_VER=3.7

FROM python:${PY_VER}-bullseye

RUN apt-get update && \
    apt-get upgrade -y && \
    echo 'apt: install deps' && \
    DEBIAN_FRONTEND=noninteractive apt-get -y --no-install-recommends install \
        apt-utils build-essential curl file gfortran git libatlas-base-dev \
        libavcodec-dev libavformat-dev libjpeg-dev libpng-dev libswscale-dev \
        libv4l-dev libx264-dev libxvidcore-dev pkg-config

ENV PATH="/opt/venv/bin:$PATH" \
    PIP_ARGS="-i https://www.dresrv.com/pip --extra-index-url https://pypi.org/simple"

RUN python -m venv /opt/venv && \
    pip install -U pip wheel setuptools && \
    echo 'pip: install deps' && \
    pip install ${PIP_ARGS} -U 'numpy<1.19' pillow

ARG OPENCV_VERSION=latest
ARG CMAKE_VERSION=latest
ARG MAKE_PIP=1
ENV OPENCV_VERSION=${OPENCV_VERSION} \
    CMAKE_VERSION=${CMAKE_VERSION} \
    MAKE_PIP=${MAKE_PIP}

COPY files/download.sh /root/download.sh
RUN /root/download.sh && \
    /tmp/cmake.sh --skip-license --prefix=/usr/local

COPY files/make-deb.sh /root/make.sh

WORKDIR /root
CMD ["/root/make.sh"]
