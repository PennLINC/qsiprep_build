# QSIPrep Docker Container Image
# significant portions copied from the fMRIPrep Docker Container Image distribution
#
# MIT License
#
# Copyright (c) 2021 The NiPreps Developers
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

# Use Ubuntu 16.04 LTS - very old but required for eddy-CUDA
FROM nvidia/cuda:9.1-runtime-ubuntu16.04

# Pre-cache neurodebian key
COPY docker/files/neurodebian.gpg /usr/local/etc/neurodebian.gpg
ARG buildcpus=2

# Prepare environment
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
                    autoconf \
                    bc \
                    build-essential \
                    bzip2 \
                    ca-certificates \
                    curl \
                    dc \
                    file \
                    freeglut3-dev \
                    freetds-common \
                    g++ \
                    gcc \
                    gfortran \
                    git \
                    imagemagick \
                    libblas-dev \
                    libboost-all-dev \
                    libclang1-5.0 \
                    libeigen3-dev \
                    libfftw3-dev libtiff5-dev \
                    libfontconfig1 \
                    libfreetype6 \
                    libgl1-mesa-dev \
                    libgl1-mesa-dev \
                    libglu1-mesa-dev \
                    libglu1-mesa-dev \
                    libgomp1 \
                    libice6 \
                    liblapack-dev \
                    libllvm5.0 \
                    libodbc1 \
                    libopenblas-base \
                    libsdl2-2.0-0 \
                    libsndio6.1 \
                    libsybdb5 \
                    libtool \
                    libxcb-xinerama0 \
                    libxcursor1 \
                    libxft2 \
                    libxinerama1 \
                    libxrandr2 \
                    libxrender1 \
                    libxt6 \
                    make \
                    mesa-utils \
                    pkg-config \
                    python \
                    python-numpy \
                    software-properties-common \
                    unzip \
                    wget \
                    xvfb \
                    zlib1g \
                    zlib1g-dev && \
    curl -sL https://deb.nodesource.com/setup_10.x | bash - && \
    apt-get install -y --no-install-recommends \
      nodejs && \
    apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Install latest pandoc
RUN curl -o pandoc-2.2.2.1-1-amd64.deb -sSL "https://github.com/jgm/pandoc/releases/download/2.2.2.1/pandoc-2.2.2.1-1-amd64.deb" && \
    dpkg -i pandoc-2.2.2.1-1-amd64.deb && \
    rm pandoc-2.2.2.1-1-amd64.deb

# Install qt5.12.2
RUN add-apt-repository ppa:beineri/opt-qt-5.12.2-xenial \
    && apt-get update \
    && apt install -y --no-install-recommends \
    qt5123d qt512base qt512canvas3d \
    qt512connectivity qt512declarative qt512graphicaleffects \
    qt512imageformats qt512location qt512multimedia qt512scxml qt512svg \
    qt512wayland qt512x11extras qt512xmlpatterns qt512charts-no-lgpl \
    && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ENV QT_BASE_DIR="/opt/qt512"
ENV QTDIR="$QT_BASE_DIR" \
    PATH="$QT_BASE_DIR/bin:$PATH:/opt/dsi-studio/dsi_studio_64" \
    LD_LIBRARY_PATH="$QT_BASE_DIR/lib/x86_64-linux-gnu:$QT_BASE_DIR/lib:$LD_LIBRARY_PATH" \
    PKG_CONFIG_PATH="$QT_BASE_DIR/lib/pkgconfig:$PKG_CONFIG_PATH"

# Installing freesurfer
RUN curl -sSL https://surfer.nmr.mgh.harvard.edu/pub/dist/freesurfer/6.0.1/freesurfer-Linux-centos6_x86_64-stable-pub-v6.0.1.tar.gz | tar zxv --no-same-owner -C /opt \
    --exclude='freesurfer/trctrain' \
    --exclude='freesurfer/subjects/fsaverage_sym' \
    --exclude='freesurfer/subjects/fsaverage3' \
    --exclude='freesurfer/subjects/fsaverage4' \
    --exclude='freesurfer/subjects/cvs_avg35' \
    --exclude='freesurfer/subjects/cvs_avg35_inMNI152' \
    --exclude='freesurfer/subjects/bert' \
    --exclude='freesurfer/subjects/V1_average' \
    --exclude='freesurfer/average/mult-comp-cor' \
    --exclude='freesurfer/lib/cuda' \
    --exclude='freesurfer/lib/qt'

  ENV FSLDIR="/opt/fsl-6.0.3" \
      PATH="/opt/fsl-6.0.3/bin:$PATH"
  RUN echo "Downloading FSL ..." \
      && mkdir -p /opt/fsl-6.0.3 \
      && curl -fsSL --retry 5 https://fsl.fmrib.ox.ac.uk/fsldownloads/fsl-6.0.3-centos6_64.tar.gz \
      | tar -xz -C /opt/fsl-6.0.3 --strip-components 1 \
      --exclude='fsl/doc' \
      --exclude='fsl/data/atlases' \
      --exclude='fsl/data/possum' \
      --exclude='fsl/src' \
      --exclude='fsl/extras/src' \
      --exclude='fsl/bin/fslview*' \
      --exclude='fsl/bin/FSLeyes' \
      && echo "Installing FSL conda environment ..." \
      && sed -i -e "/fsleyes/d" -e "/wxpython/d" \
         ${FSLDIR}/etc/fslconf/fslpython_environment.yml \
      && bash /opt/fsl-6.0.3/etc/fslconf/fslpython_install.sh -f /opt/fsl-6.0.3 \
      && find ${FSLDIR}/fslpython/envs/fslpython/lib/python3.7/site-packages/ -type d -name "tests"  -print0 | xargs -0 rm -r \
      && ${FSLDIR}/fslpython/bin/conda clean --all

ENV FREESURFER_HOME=/opt/freesurfer \
    SUBJECTS_DIR=/opt/freesurfer/subjects \
    FUNCTIONALS_DIR=/opt/freesurfer/sessions \
    MNI_DIR=/opt/freesurfer/mni \
    LOCAL_DIR=/opt/freesurfer/local \
    FSFAST_HOME=/opt/freesurfer/fsfast \
    MINC_BIN_DIR=/opt/freesurfer/mni/bin \
    MINC_LIB_DIR=/opt/freesurfer/mni/lib \
    MNI_DATAPATH=/opt/freesurfer/mni/data \
    FMRI_ANALYSIS_DIR=/opt/freesurfer/fsfast
ENV PERL5LIB=$MINC_LIB_DIR/perl5/5.8.5 \
    MNI_PERL5LIB=$MINC_LIB_DIR/perl5/5.8.5 \
    PATH=$FREESURFER_HOME/bin:$FSFAST_HOME/bin:$FREESURFER_HOME/tktools:$MINC_BIN_DIR:$PATH

# Installing Neurodebian packages (FSL, AFNI, git)
RUN curl -sSL "http://neuro.debian.net/lists/$( lsb_release -c | cut -f2 ).us-ca.full" >> /etc/apt/sources.list.d/neurodebian.sources.list && \
    apt-key add /usr/local/etc/neurodebian.gpg && \
    (apt-key adv --refresh-keys --keyserver hkp://ha.pool.sks-keyservers.net 0xA5D32F012649A5A9 || true)

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
                    afni=16.2.07~dfsg.1-5~nd16.04+1 \
                    git-annex-standalone && \
    apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*


# Install DSI Studio
ENV QT_BASE_DIR="/opt/qt512"
ENV QTDIR="$QT_BASE_DIR" \
    PATH="$QT_BASE_DIR/bin:$PATH:/opt/dsi-studio/dsi_studio_64" \
    LD_LIBRARY_PATH="$QT_BASE_DIR/lib/x86_64-linux-gnu:$QT_BASE_DIR/lib:$LD_LIBRARY_PATH" \
    PKG_CONFIG_PATH="$QT_BASE_DIR/lib/pkgconfig:$PKG_CONFIG_PATH"
ARG DSI_SHA=eb8433e8923d4bb26bd6ee04d0da4bdede55ed85
ARG TIPL_SHA=f94d2df66acba0fa929351a0a2bdfaa40faf66e8
RUN mkdir /opt/dsi-studio \
  && cd /opt/dsi-studio \
  && curl -sSLO https://github.com/frankyeh/DSI-Studio/archive/${DSI_SHA}.zip \
  && unzip ${DSI_SHA}.zip \
  && mv DSI-Studio-${DSI_SHA} src \
  && rm -rf ${DSI_SHA}.zip \
  && curl -sSLO https://github.com/frankyeh/TIPL/archive/${TIPL_SHA}.zip \
  && unzip ${TIPL_SHA}.zip \
  && mv TIPL-${TIPL_SHA} src/tipl \
  && rm ${TIPL_SHA}.zip \
  && mkdir build && cd build \
  && /opt/qt512/bin/qmake ../src && make -j ${buildcpus} \
  && cd /opt/dsi-studio \
  && curl -sSLO 'https://upenn.box.com/shared/static/01r73d4a15utl13himv4d7cjpa6etf6z.gz' \
  && tar xvfz 01r73d4a15utl13himv4d7cjpa6etf6z.gz \
  && rm 01r73d4a15utl13himv4d7cjpa6etf6z.gz \
  && cd dsi_studio_64 \
  && mv ../build/dsi_studio . \
  && rm -rf /opt/dsi-studio/src /opt/dsi-studio/build


# Install mrtrix3 from source
ARG MRTRIX_SHA=3498ff469b843d5b023c3675f1d955ba4105c5d1
ENV PATH="/opt/mrtrix3-latest/bin:$PATH"
RUN cd /opt \
    && curl -sSLO https://github.com/MRtrix3/mrtrix3/archive/${MRTRIX_SHA}.zip \
    && unzip ${MRTRIX_SHA}.zip \
    && mv mrtrix3-${MRTRIX_SHA} /opt/mrtrix3-latest \
    && rm ${MRTRIX_SHA}.zip \
    && cd /opt/mrtrix3-latest \
    && ./configure -nogui \
    && echo "Compiling MRtrix3 ..." \
    && ./build

# Install 3Tissue from source
ARG MRTRIX_SHA=c1367255f51a3cbe774c8317448cdc0b0aa587be
ENV PATH="/opt/mrtrix3-latest/bin:$PATH"
RUN cd /opt \
    && curl -sSLO https://github.com/3Tissue/MRtrix3Tissue/archive/${MRTRIX_SHA}.zip \
    && unzip ${MRTRIX_SHA}.zip \
    && mv MRtrix3Tissue-${MRTRIX_SHA} /opt/3Tissue \
    && rm ${MRTRIX_SHA}.zip \
    && cd /opt/3Tissue \
    && ./configure -nogui \
    && echo "Compiling MRtrix3-3Tissue ..." \
    && ./build

ENV C3DPATH="/opt/convert3d-nightly" \
    PATH="/opt/convert3d-nightly/bin:$PATH"
RUN echo "Downloading Convert3D ..." \
    && mkdir -p /opt/convert3d-nightly \
    && curl -fsSLk --retry 5 https://sourceforge.net/projects/c3d/files/c3d/Nightly/c3d-nightly-Linux-x86_64.tar.gz/download \
    | tar -xz -C /opt/convert3d-nightly --strip-components 1

# Create a shared $HOME directory
RUN useradd -m -s /bin/bash -G users qsiprep
WORKDIR /home/qsiprep
ENV HOME="/home/qsiprep"

# Installing SVGO
RUN curl -sL https://deb.nodesource.com/setup_10.x | bash -
RUN apt-get install -y nodejs
RUN npm install -g svgo

# Installing bids-validator
RUN npm install -g bids-validator@1.2.3

# Installing and setting up miniconda
RUN curl -sSLO https://repo.anaconda.com/miniconda/Miniconda3-py38_4.10.3-Linux-x86_64.sh && \
    bash Miniconda3-py38_4.10.3-Linux-x86_64.sh -b -p /usr/local/miniconda && \
    rm Miniconda3-py38_4.10.3-Linux-x86_64.sh

# Unless otherwise specified each process should only use one thread - nipype
# will handle parallelization
ENV MKL_NUM_THREADS=1 \
    OMP_NUM_THREADS=1 \
    MRTRIX_NTHREADS=1 \
    KMP_WARNINGS=0

WORKDIR /root/

# Precaching atlases
ENV CRN_SHARED_DATA /niworkflows_data
ADD docker/scripts/get_templates.sh get_templates.sh
RUN mkdir $CRN_SHARED_DATA && \
    /root/get_templates.sh && \
    chmod -R a+rX $CRN_SHARED_DATA

RUN ln -s /opt/fsl-6.0.3/bin/eddy_cuda9.1 /opt/fsl-6.0.3/bin/eddy_cuda

# Installing ANTs latest from source
ARG ANTS_SHA=e00e8164d7a92f048e5d06e388a15c1ee8e889c4
# Add file originally from https://cmake.org/files/v3.11/cmake-3.11.4-Linux-x86_64.sh
COPY docker/files/cmake-3.11.4-Linux-x86_64.sh  /cmake-3.11.4-Linux-x86_64.sh
RUN mkdir /opt/cmake \
  && sh /cmake-3.11.4-Linux-x86_64.sh --prefix=/opt/cmake --skip-license \
  && ln -s /opt/cmake/bin/cmake /usr/local/bin/cmake \
  && apt-get update -qq \
    && mkdir /tmp/ants \
    && cd /tmp \
    && git clone https://github.com/ANTsX/ANTs.git \
    && mv ANTs /tmp/ants/source \
    && cd /tmp/ants/source \
    && git checkout ${ANTS_SHA} \
    && mkdir -p /tmp/ants/build \
    && cd /tmp/ants/build \
    && mkdir -p /opt/ants-latest \
    && git config --global url."https://".insteadOf git:// \
    && cmake -DBUILD_TESTING=OFF -DBUILD_SHARED_LIBS=ON -DCMAKE_INSTALL_PREFIX=/opt/ants-latest /tmp/ants/source \
    && make -j ${buildcpus} \
    && cd ANTS-build \
    && make install \
    && rm -rf /tmp/ants \
    && rm -rf /opt/cmake /usr/local/bin/cmake /cmake-3.11.4-Linux-x86_64.sh


ENV ANTSPATH="/opt/ants-latest/bin" \
    LD_LIBRARY_PATH="/opt/ants-latest/lib:$LD_LIBRARY_PATH" \
    AFNI_INSTALLDIR=/usr/lib/afni \
    PATH=${PATH}:/usr/lib/afni/bin \
    AFNI_PLUGINPATH=/usr/lib/afni/plugins \
    AFNI_MODELPATH=/usr/lib/afni/models \
    AFNI_TTATLAS_DATASET=/usr/share/afni/atlases \
    AFNI_IMSAVE_WARNINGS=NO \
    FSLOUTPUTTYPE=NIFTI_GZ \
    MRTRIX_NTHREADS=1 \
    IS_DOCKER_8395080871=1 \
    DIPY_HOME=/home/qsiprep/.dipy

ENV PATH="/usr/local/miniconda/bin:${ANTSPATH}:${PATH}"

# Make singularity mount directories
RUN  mkdir -p /sngl/data \
  && mkdir /sngl/qsiprep-output \
  && mkdir /sngl/out \
  && mkdir /sngl/scratch \
  && mkdir /sngl/spec \
  && mkdir /sngl/eddy \
  && mkdir /sngl/filter \
  && chmod a+rwx /sngl/*
