#! /bin/bash

# COLORS
ORANGE='\033[38;5;214m'
NC='\033[0m'


DEFAULT_TAG="4.9.0"
OPENCV_REPO="https://github.com/opencv/opencv.git"
OPENCV_CONTRIB_REPO="https://github.com/opencv/opencv_contrib.git"
OPENCV_FOLDER=`echo $OPENCV_REPO | cut -d "/" -f 5 | cut -d "." -f 1`
OPENCV_CONTRIB_FOLDER=`echo $OPENCV_CONTRIB_REPO | cut -d "/" -f 5 | cut -d "." -f 1`

help()
{
   # Display Help
   echo "OpenCV installer"
   echo
   echo "Syntax: scriptTemplate [-t|d|h]"
   echo "options:"
   echo "t     OpenCV version tag."
   echo "d     Directory to install."
   echo "h     Show this help message."
   echo
}


while getopts t:d:h flag
do
    case "${flag}" in
        t) TAG=${OPTARG};;
        d) DIR=${OPTARG};;
        h) Help;exit;;
    esac
done

if [ -z "$TAG" ]; then
  echo -e "${ORANGE}Tag is not provided using default tag: $DEFAULT_TAG${NC}"
  TAG=$DEFAULT_TAG
fi

if [ -z "$DIR" ]; then
  echo -e "${ORANGE}Directory is not provideo using current directory${NC}"
  DIR=$PWD
else
  cd $DIR
fi

install_dependencies () {
    sudo apt install -y build-essential cmake pkg-config unzip yasm git checkinstall \
    libjpeg-dev libpng-dev libtiff-dev libswresample-dev \
    libavcodec-dev libavformat-dev libswscale-dev \
    libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev \
    libxvidcore-dev x264 libx264-dev libmp3lame-dev libtheora-dev  \
    libfaac-dev libmp3lame-dev libvorbis-dev \
    libopencore-amrnb-dev libopencore-amrwb-dev \
    libdc1394-22 libdc1394-22-dev libxine2-dev libv4l-dev v4l-utils \
    libgtk-3-dev libtbb-dev libatlas-base-dev gfortran \
    libprotobuf-dev protobuf-compiler \
    libgoogle-glog-dev libgflags-dev \
    libgphoto2-dev libeigen3-dev libhdf5-dev doxygen

    cd /usr/include/linux
    sudo ln -s -f ../libv4l1-videodev.h videodev.h
    cd $DIR
}

clone_opencv_repo(){
  git clone --depth 1 --branch $TAG $OPENCV_REPO
  cd $OPENCV_FOLDER
  git clone --depth 1 --branch $TAG $OPENCV_CONTRIB_REPO
  cd $DIR
}

build () {
  cd $OPENCV_FOLDER
  mkdir build && cd build

  cmake -D CMAKE_BUILD_TYPE=RELEASE \
        -D CMAKE_INSTALL_PREFIX=/usr/local \
        -D WITH_TBB=ON \
        -D ENABLE_FAST_MATH=1 \
        -D CUDA_FAST_MATH=1 \
        -D WITH_CUBLAS=1 \
        -D WITH_CUDA=ON \
        -D BUILD_opencv_cudacodec=OFF \
        -D WITH_CUDNN=ON \
        -D OPENCV_DNN_CUDA=ON \
        -D CMAKE_C_COMPILER=gcc-12 \
        -D CMAKE_CXX_COMPILER=g++-12 \
        -D CUDA_ARCH_BIN=`nvidia-smi --query-gpu=compute_cap --format=csv | sed -n 2p` \
        -D WITH_V4L=ON \
        -D WITH_QT=OFF \
        -D WITH_OPENGL=ON \
        -D WITH_GSTREAMER=ON \
        -D OPENCV_GENERATE_PKGCONFIG=ON \
        -D OPENCV_PC_FILE_NAME=opencv.pc \
        -D OPENCV_ENABLE_NONFREE=ON \
        -D OPENCV_EXTRA_MODULES_PATH=../$OPENCV_CONTRIB_FOLDER/modules \
        -D INSTALL_PYTHON_EXAMPLES=OFF \
        -D INSTALL_C_EXAMPLES=OFF \
        -D BUILD_EXAMPLES=OFF .. \
        || echo "Errors occured when configuring" | exit 1
        # -D OPENCV_PYTHON3_INSTALL_PATH=~/.venv/cv/lib/python3.8/site-packages \
        # -D PYTHON_EXECUTABLE=~/.venv/cv/bin/python \
  

  make -j`nproc`
  sudo make install
}

sudo bash -c "$(declare -f install_dependencies); install_dependencies"
clone_opencv_repo
build
