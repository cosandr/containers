FROM python:3.7-slim as base

FROM base as builder

ARG TF_FILE=tensorflow-1.14.0-cp37-cp37m-linux_x86_64.whl

COPY src-brains/requirements.txt /tmp/req.txt
COPY files/${TF_FILE} /tmp/

ENV PATH="/opt/venv/bin:$PATH"

RUN python -m venv /opt/venv && \
    apt-get update && \
    apt-get upgrade -y && \
    echo 'apt: install deps' && \
    apt-get -y --no-install-recommends install build-essential git && \
    echo 'pip: install deps' && \
    sed -i 's/^tensorflow.*//g' /tmp/req.txt && \
    sed -i 's/^opencv.*//g' /tmp/req.txt && \
    pip install --no-cache-dir -r /tmp/req.txt && \
    pip install --no-cache-dir tensorflow_hub /tmp/${TF_FILE}

FROM base

ARG OVERLAY_VERSION="v2.1.0.0"

ADD https://github.com/just-containers/s6-overlay/releases/download/${OVERLAY_VERSION}/s6-overlay-amd64.tar.gz /tmp/
COPY files/opencv/* /tmp/opencv/
COPY --from=builder /opt/venv /opt/venv

ENV PATH="/opt/venv/bin:$PATH" \
LANGUAGE="en_US.UTF-8" \
LANG="en_US.UTF-8" \
TERM="xterm" \
PYTHONUNBUFFERED="1"

RUN apt-get update && \
    apt-get upgrade -y && \
    echo '**** apt: install deps ****' && \
    apt-get -y --no-install-recommends install sudo locales ffmpeg tar && \
    echo '**** OpenCV: Install ****' && \
    dpkg -i --force-depends /tmp/opencv/*.deb && \
    apt-get install -y -f --no-install-recommends && \
    echo '**** S6: Install ****' && \
    tar xzf /tmp/s6-overlay-amd64.tar.gz -C / && \
    echo '**** user: Create abc user and group ****' && \
    groupadd --gid 1000 abc && useradd --create-home --gid 1000 --uid 1000 abc && \
    echo '**** locale setup ****' && \
    locale-gen en_US.UTF-8 && \
    echo "**** cleanup ****" && \
    apt-get clean && \
    rm -rf \
        /tmp/* \
        /var/lib/apt/lists/* \
        /var/tmp/*

VOLUME [ "/app", "/data", "/upload" ]

COPY files/root/ /
COPY files/root-brains/ /
ENTRYPOINT [ "/init" ]
