#!/bin/bash

set -e

if [[ $MAKE_PIP == "1" ]]; then
    cd /root/opencv

    export CMAKE_ARGS='-DWITH_FFMPEG=1'
    export ENABLE_HEADLESS=1
    export ENABLE_CONTRIB=0
    export MAKEFLAGS=-j$(nproc)

    pip wheel . --verbose

    rm -fv /data/*.whl

    cp -v /root/opencv/*.whl /data/

    PUID=${PUID:-1000}
    PGID=${PGID:-1000}

    chown -Rv "${PUID}":"${PGID}" /data
else
    cd /root/opencv/build
    cmake \
    -DCMAKE_BUILD_TYPE=RELEASE \
    -DCMAKE_INSTALL_PREFIX=/usr/local \
    -DCPACK_BINARY_DEB=ON \
    -DBUILD_SHARED_LIBS=OFF \
    -DBUILD_LIST=core\,python3\,imgcodecs\,imgproc\,photo\,stitching\,video\,videoio \
    -DINSTALL_C_EXAMPLES=OFF \
    -DINSTALL_PYTHON_EXAMPLES=OFF \
    -DBUILD_EXAMPLES=OFF \
    -DBUILD_TESTS=OFF \
    -DBUILD_PERF_TESTS=OFF \
    -DBUILD_DOCS=OFF \
    -DBUILD_JAVA=OFF \
    -DBUILD_opencv_python2=OFF \
    -DWITH_FFMPEG=1 \
    -DWITH_CUDA=OFF \
    -DWITH_IPP=OFF \
    -DWITH_OPENCL=OFF \
    -DWITH_GTK=0 \
    -DOPENCV_SKIP_PYTHON_LOADER=ON \
    -DOPENCV_PYTHON3_INSTALL_PATH=/opt/venv/lib/python3.7/site-packages \
    ..

    # Compile
    make -j$(nproc)

    # Install
    make install

    # Create packages
    make package

    rm -fv /data/*.deb

    cp -v /root/opencv/build/*.deb /data/

    PUID=${PUID:-1000}
    PGID=${PGID:-1000}

    chown -Rv "${PUID}":"${PGID}" /data
fi
