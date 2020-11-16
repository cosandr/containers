#!/bin/bash

set -e -o pipefail

if [[ -n $TF_VERSION && $TF_VERSION == "latest" ]]; then
    TF_TAG=$(curl --silent "https://api.github.com/repos/tensorflow/tensorflow/releases/latest" | grep -Po '"tag_name": "\K.*?(?=")')
    if [[ $? -ne 0 ]]; then
        echo "Cannot get latest Tensorflow tag: $TF_TAG"
        exit 1
    fi
else
    TF_TAG="$TF_VERSION"
fi

cd /src || exit 1

git fetch
echo -e "\n\tTensorflow: Checkout $TF_TAG"
git reset --hard "$TF_TAG"
git clean -xdf
git checkout "$TF_TAG"

# Fix Python 3.8+ build if needed
# Get patches with git log --reverse --grep '[pP]y.*3\.8' master
PY_VER=$(python -V)
echo -e "\n\tTensorflow $TF_TAG: Python $PY_VER"
if [[ $PY_VER =~ 3\.[89] ]]; then
    if [[ $TF_TAG =~ 1\.15 ]]; then
        echo -e "\n\tTensorflow 1.15: Applying Python 3.8+ patches"
        # git apply /tmp/tensorflow-1.15-cuda10.2-python3.8.diff
        git apply /tmp/tensorflow-1.15-python3.8.patch
        # git config merge.renamelimit 5000
        # git cherry-pick -n \
        #     3a48a5c1541daa1fc3f49b9dbe0da247e7cd90f3 \
        #     ea3063c929c69f738bf65bc99dad1159803e772f \
        #     507d1888156ec7c13d61c50c7a440abc86b3b48b
    elif [[ $TF_TAG =~ 1\.14 ]]; then
        echo -e "\n\tTensorflow 1.14: Applying Python 3.8+ patches"
        git apply /tmp/tensorflow-1.14-python3.8.patch
    fi
fi
