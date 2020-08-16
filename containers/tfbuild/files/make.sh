#!/bin/bash

cd /root/tensorflow || exit

export PYTHON_BIN_PATH=/usr/local/bin/python
export USE_DEFAULT_PYTHON_LIB_PATH=1
export TF_NEED_JEMALLOC=1
export TF_NEED_KAFKA=0
export TF_NEED_OPENCL_SYCL=0
export TF_NEED_AWS=0
export TF_NEED_GCP=0
export TF_NEED_HDFS=0
export TF_NEED_S3=0
export TF_ENABLE_XLA=1
export TF_NEED_GDR=0
export TF_NEED_VERBS=0
export TF_NEED_OPENCL=0
export TF_NEED_MPI=0
export TF_NEED_TENSORRT=0
export TF_NEED_NGRAPH=0
export TF_NEED_IGNITE=0
export TF_NEED_ROCM=0
export TF_SET_ANDROID_WORKSPACE=0
export TF_DOWNLOAD_CLANG=0
export TF_IGNORE_MAX_BAZEL_VERSION=0
export GCC_HOST_COMPILER_PATH=/usr/bin/gcc
export HOST_CXX_COMPILER_PATH=/usr/bin/gcc
export TF_CUDA_CLANG=0
export CC_OPT_FLAGS="-march=skylake"
export TF_NEED_CUDA=0

./configure

bazel build \
    --config=opt --incompatible_no_support_tools_in_action_inputs=false \
    //tensorflow/tools/pip_package:build_pip_package

# Build wheel
./bazel-bin/tensorflow/tools/pip_package/build_pip_package /data/

PUID=${PUID:-1000}
PGID=${PGID:-1000}

chown -Rv "${PUID}":"${PGID}" /data
