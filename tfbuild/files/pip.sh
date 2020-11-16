#!/bin/bash

if [[ $USE_TF_PIP -eq 1 ]]; then
    grep -P '(^pip3 install|pip3 install --upgrade numpy==\S+)' /src/tensorflow/tools/ci_build/install/install_pip_packages.sh > /tmp/install-pip.sh

    chmod +x /tmp/install-pip.sh
    /tmp/install-pip.sh
elif [[ $TF_VERSION =~ 1\.14 ]]; then
    pip install -U 'numpy<1.19.0'
    pip install -U pip six wheel mock
    pip install -U future
    pip install -U keras_applications==1.0.4 --no-deps
    pip install -U keras_preprocessing==1.0.2 --no-deps
    pip install -U pandas
else
    pip install -U 'numpy<1.19.0'
    pip install -U pip six wheel mock
    pip install -U future
    pip install -U keras_applications==1.0.8 --no-deps
    pip install -U keras_preprocessing==1.1.2 --no-deps
    pip install -U pandas
fi
