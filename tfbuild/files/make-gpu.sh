#!/bin/bash

export PROJECT_NAME="tensorflow_gpu"
export PYTHON_BIN_PATH=/opt/venv/bin/python
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
export TF_NEED_NGRAPH=0
export TF_NEED_IGNITE=0
export TF_NEED_ROCM=0
export TF_SET_ANDROID_WORKSPACE=0
export TF_DOWNLOAD_CLANG=0
export TF_IGNORE_MAX_BAZEL_VERSION=0
export GCC_HOST_COMPILER_PATH=/usr/bin/gcc
export HOST_CXX_COMPILER_PATH=/usr/bin/gcc
export TF_CUDA_CLANG=1
export CC_OPT_FLAGS="-march=native -O3"
export TF_NEED_CUDA=1
export TF_CUDA_VERSION=10
export TF_NEED_TENSORRT=1
export TF_CUDNN_VERSION=7
export TENSORRT_INSTALL_PATH=/usr/local/tensorrt
export LD_LIBRARY_PATH="/usr/local/cuda:/usr/local/cuda/lib64:/usr/local/cuda/extras/CUPTI/lib64:$TENSORRT_INSTALL_PATH/lib"
export TF_CUDA_COMPUTE_CAPABILITIES=3.5,3.7,5.2,6.0,6.1,7.0

set -e

./configure

bazel build \
    --config=nohdfs \
    --config=noaws \
    --config=nogcp \
    --config=opt \
    //tensorflow/tools/pip_package:build_pip_package

# Build wheel
./bazel-bin/tensorflow/tools/pip_package/build_pip_package /data/ --gpu --project_name "$PROJECT_NAME"

PUID=${PUID:-1000}
PGID=${PGID:-1000}

chown -Rv "${PUID}":"${PGID}" /data
