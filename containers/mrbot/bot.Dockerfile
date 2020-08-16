FROM python:3.8-slim as base

FROM base as builder

COPY src/requirements.txt /tmp/req.txt

ENV PATH="/opt/venv/bin:$PATH"

RUN python -m venv /opt/venv && \
    apt-get update && \
    apt-get upgrade -y && \
    echo 'apt: install deps' && \
    apt-get -y install build-essential git && \
    echo 'pip: install deps' && \
    pip install --no-cache-dir -r /tmp/req.txt

FROM base

ARG OVERLAY_VERSION="v2.0.0.1"

ADD https://github.com/just-containers/s6-overlay/releases/download/${OVERLAY_VERSION}/s6-overlay-amd64.tar.gz /tmp/
COPY --from=builder /opt/venv /opt/venv

ENV PATH="/opt/venv/bin:$PATH" \
LANGUAGE="en_US.UTF-8" \
LANG="en_US.UTF-8" \
TERM="xterm" \
PYTHONUNBUFFERED="1"

RUN apt-get update && \
    apt-get upgrade -y && \
    echo '**** apt: install deps ****' && \
    apt-get -y --no-install-recommends install \
        sudo locales texlive dvipng libffi-dev libnacl-dev libopus-dev ffmpeg && \
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

COPY files/root/ /
COPY files/root-bot/ /

ENTRYPOINT [ "/init" ]
