#!/bin/bash

set -e -o pipefail

if [[ $CMAKE_VERSION == "latest" ]]; then
    CMAKE_TAG=$(curl --silent "https://api.github.com/repos/Kitware/CMake/releases/latest" | grep -Po '"tag_name": "v\K.*?(?=")')
    if [[ $? -ne 0 ]]; then
        echo "Cannot get latest CMake tag: $CMAKE_TAG"
        exit 1
    fi
else
    CMAKE_TAG="$CMAKE_VERSION"
fi

if [[ $MAKE_PIP == "1" ]]; then
    CV_REPO="opencv/opencv-python"
    GIT_ARGS="--recursive"
else
    CV_REPO="opencv/opencv"
    GIT_ARGS="--single-branch"
fi

if [[ $OPENCV_VERSION == "latest" ]]; then
    OPENCV_TAG=$(curl --silent "https://api.github.com/repos/${CV_REPO}/releases/latest" | grep -Po '"tag_name": "\K.*?(?=")')
    if [[ $? -ne 0 ]]; then
        echo "Cannot get latest OpenCV tag: $OPENCV_TAG"
        exit 1
    fi
else
    OPENCV_TAG="$OPENCV_VERSION"
fi

echo -e "\n\tOpenCV: Cloning $OPENCV_TAG"
git clone -b "$OPENCV_TAG" "$GIT_ARGS" "https://github.com/${CV_REPO}.git" /root/opencv
[[ $MAKE_PIP != "1" ]] && mkdir /root/opencv/build

echo -e "\n\tCMake: Downloading $CMAKE_TAG"
curl -L --silent -o /tmp/cmake.sh "https://github.com/Kitware/CMake/releases/download/v${CMAKE_TAG}/cmake-${CMAKE_TAG}-$(uname -s)-$(uname -m).sh"
chmod +x /tmp/cmake.sh
