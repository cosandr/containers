#!/bin/bash

set -e -o pipefail

if [[ $BAZEL_VERSION == "latest" ]]; then
    BAZEL_TAG=$(curl --silent "https://api.github.com/repos/bazelbuild/bazel/releases/latest" | grep -Po '"tag_name": "\K.*?(?=")')
    if [[ $? -ne 0 ]]; then
        echo "Cannot get latest Bazel tag: $BAZEL_TAG"
        exit 1
    fi
else
    BAZEL_TAG="$BAZEL_VERSION"
fi

if [[ $TF_VERSION == "latest" ]]; then
    TF_TAG=$(curl --silent "https://api.github.com/repos/tensorflow/tensorflow/releases/latest" | grep -Po '"tag_name": "\K.*?(?=")')
    if [[ $? -ne 0 ]]; then
        echo "Cannot get latest Tensorflow tag: $TF_TAG"
        exit 1
    fi
else
    TF_TAG="$TF_VERSION"
fi

echo -e "\n\tTensorflow: Cloning $TF_TAG"
git clone -b "$TF_TAG" --single-branch https://github.com/tensorflow/tensorflow.git /root/tensorflow

echo -e "\n\tBazel: Downloading $BAZEL_TAG"
curl -L --silent -o /tmp/bazel.sh "https://github.com/bazelbuild/bazel/releases/download/${BAZEL_TAG}/bazel-${BAZEL_TAG}-installer-linux-x86_64.sh"
chmod +x /tmp/bazel.sh
