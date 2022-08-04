ARG TAG_FSL
ARG TAG_FREESURFER
ARG TAG_ANTS
ARG TAG_MRTRIX3
ARG TAG_3TISSUE
ARG TAG_DSISTUDIO
ARG TAG_MINICONDA
ARG TAG_AFNI

# COPY can't handle variables, so here we go
FROM pennbbl/qsiprep-fsl:${TAG_FSL} as build_fsl
FROM pennbbl/qsiprep-freesurfer:${TAG_FREESURFER} as build_freesurfer
FROM pennbbl/qsiprep-ants:${TAG_ANTS} as build_ants
FROM pennbbl/qsiprep-mrtrix3:${TAG_MRTRIX3} as build_mrtrix3
FROM pennbbl/qsiprep-3tissue:${TAG_3TISSUE} as build_3tissue
FROM pennbbl/qsiprep-dsistudio:${TAG_DSISTUDIO} as build_dsistudio
FROM pennbbl/qsiprep-miniconda:${TAG_MINICONDA} as build_miniconda
FROM pennbbl/qsiprep-afni:${TAG_AFNI} as build_afni
FROM nvidia/cuda:10.2-runtime-ubuntu18.04 as cuda10

FROM cuda10
## FSL
COPY --from=build_fsl /opt/fsl-6.0.5.1 /opt/fsl-6.0.5.1
ENV FSLDIR="/opt/fsl-6.0.5.1" \
    FSLOUTPUTTYPE="NIFTI_GZ" \
    FSLMULTIFILEQUIT="TRUE" \
    FSLLOCKDIR="" \
    FSLMACHINELIST="" \
    FSLREMOTECALL="" \
    FSLGECUDAQ="cuda.q" \
    LD_LIBRARY_PATH="/opt/fsl-6.0.5.1/lib:$LD_LIBRARY_PATH" \
    PATH="/opt/fsl-6.0.5.1/bin:$PATH" \
    FSL_DEPS="libquadmath0"

## ANTs
COPY --from=build_ants /opt/ants /opt/ants
ENV ANTSPATH="/opt/ants/bin" \
    LD_LIBRARY_PATH="/opt/ants/lib:$LD_LIBRARY_PATH" \
    PATH="$PATH:/opt/ants/bin" \
    ANTS_DEPS="zlib1g-dev"

## DSI Studio
ENV QT_BASE_DIR="/opt/qt512"
ENV QTDIR="$QT_BASE_DIR" \
    LD_LIBRARY_PATH="$QT_BASE_DIR/lib/x86_64-linux-gnu:$QT_BASE_DIR/lib:$LD_LIBRARY_PATH" \
    PKG_CONFIG_PATH="$QT_BASE_DIR/lib/pkgconfig:$PKG_CONFIG_PATH" \
    PATH="$QT_BASE_DIR/bin:$PATH:/opt/dsi-studio/dsi_studio_64" \
    DSI_STUDIO_DEPS="qt512base qt512charts-no-lgpl"

## MRtrix3
COPY --from=build_mrtrix3 /opt/mrtrix3-latest /opt/mrtrix3-latest
## MRtrix3-3Tissue
COPY --from=build_3tissue /opt/3Tissue /opt/3Tissue
ENV PATH="$PATH:/opt/mrtrix3-latest/bin:/opt/3Tissue/bin" \
    MRTRIX3_DEPS="bzip2 ca-certificates curl libpng16-16 libblas3 liblapack3"

## Freesurfer
COPY --from=build_freesurfer /opt/freesurfer /opt/freesurfer
# Simulate SetUpFreeSurfer.sh
ENV FSL_DIR="/opt/fsl-6.0.5.1" \
    OS="Linux" \
    FS_OVERRIDE=0 \
    FIX_VERTEX_AREA="" \
    FSF_OUTPUT_FORMAT="nii.gz" \
    FREESURFER_HOME="/opt/freesurfer"
ENV SUBJECTS_DIR="$FREESURFER_HOME/subjects" \
    FUNCTIONALS_DIR="$FREESURFER_HOME/sessions" \
    MNI_DIR="$FREESURFER_HOME/mni" \
    LOCAL_DIR="$FREESURFER_HOME/local" \
    MINC_BIN_DIR="$FREESURFER_HOME/mni/bin" \
    MINC_LIB_DIR="$FREESURFER_HOME/mni/lib" \
    MNI_DATAPATH="$FREESURFER_HOME/mni/data"
ENV PERL5LIB="$MINC_LIB_DIR/perl5/5.8.5" \
    MNI_PERL5LIB="$MINC_LIB_DIR/perl5/5.8.5" \
    PATH="$FREESURFER_HOME/bin:$FSFAST_HOME/bin:$FREESURFER_HOME/tktools:$MINC_BIN_DIR:$PATH" \
    FREESURFER_DEPS="bc ca-certificates curl libgomp1 libxmu6 libxt6 tcsh perl"

## AFNI
COPY --from=build_afni /opt/afni-latest /opt/afni-latest
ENV PATH="$PATH:/opt/afni-latest" \
    AFNI_INSTALLDIR=/opt/afni-latest \
    AFNI_IMSAVE_WARNINGS=NO

## Python, compiled dependencies
COPY --from=build_miniconda /usr/local/miniconda /usr/local/miniconda
COPY --from=build_miniconda /home/qsiprep/.dipy /home/qsiprep/.dipy
ENV PATH="/usr/local/miniconda/bin:$PATH"

RUN apt-get update -qq \
    && apt-get install -y -q --no-install-recommends \
           apt-utils \
           bzip2 \
           ca-certificates \
           curl \
           ed \
           bc \
           gsl-bin \
           libglib2.0-0 \
           libglu1-mesa-dev \
           libglw1-mesa \
           libgomp1 \
           libjpeg62 \
           libpng16-16 \
           libquadmath0 \
           libxm4 \
           libxmu6 \
           libxt6 \
           perl \
           libtiff5 \
           netpbm \
           software-properties-common \
           tcsh \
           xfonts-base \
           xvfb \
           zlib1g-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && curl -sSL --retry 5 -o /tmp/libxp6.deb http://mirrors.kernel.org/debian/pool/main/libx/libxp/libxp6_1.0.2-2_amd64.deb \
    && dpkg -i /tmp/libxp6.deb \
    && rm /tmp/libxp6.deb \
    && curl -sSL --retry 5 -o /tmp/libpng.deb http://snapshot.debian.org/archive/debian-security/20160113T213056Z/pool/updates/main/libp/libpng/libpng12-0_1.2.49-1%2Bdeb7u2_amd64.deb \
    && dpkg -i /tmp/libpng.deb \
    && rm /tmp/libpng.deb \
    && apt-get install -f --no-install-recommends \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && gsl2_path="$(find / -name 'libgsl.so.19' || printf '')" \
    && if [ -n "$gsl2_path" ]; then \
         ln -sfv "$gsl2_path" "$(dirname $gsl2_path)/libgsl.so.0"; \
    fi \
    && ldconfig \
    && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN echo "Downloading Convert3D ..." \
    && mkdir -p /opt/convert3d-nightly \
    && curl -fsSL --retry 5 https://sourceforge.net/projects/c3d/files/c3d/Nightly/c3d-nightly-Linux-x86_64.tar.gz/download \
    | tar -xz -C /opt/convert3d-nightly --strip-components 1 \
    --exclude "c3d-1.0.0-Linux-x86_64/lib" \
    --exclude "c3d-1.0.0-Linux-x86_64/share" \
    --exclude "c3d-1.0.0-Linux-x86_64/bin/c3d_gui"
ENV C3DPATH="/opt/convert3d-nightly" \
    PATH="/opt/convert3d-nightly/bin:$PATH"

# Prepare environment
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        zlib1g-dev graphviz libfftw3-3 && \
    curl -sL https://deb.nodesource.com/setup_10.x | bash - && \
    apt-get install -y --no-install-recommends \
      nodejs && \
    apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN npm install -g svgo \
    && npm install -g bids-validator@1.2.3

# Install latest pandoc
RUN curl -o pandoc-2.2.2.1-1-amd64.deb -sSL "https://github.com/jgm/pandoc/releases/download/2.2.2.1/pandoc-2.2.2.1-1-amd64.deb" && \
    dpkg -i pandoc-2.2.2.1-1-amd64.deb && \
    rm pandoc-2.2.2.1-1-amd64.deb

# Install qt5.12.8
RUN add-apt-repository ppa:beineri/opt-qt-5.12.8-bionic \
    && apt-get update \
    && apt install -y --no-install-recommends \
    ${DSI_STUDIO_DEPS} ${MRTRIX3_DEPS} wget git binutils \
    && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
COPY --from=build_dsistudio /opt/dsi-studio /opt/dsi-studio

# Install gcc-9
RUN add-apt-repository ppa:ubuntu-toolchain-r/test && \
    && apt-get update \
    && apt-get install --no-install-recommends libstdc++6 \
    && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Install ACPC-detect
WORKDIR /opt/art
ENV PATH="/opt/art/bin:$PATH"
RUN cd /opt/art \
    && curl -fsSL https://osf.io/73h5s/download \
    | tar xz --strip-components 1

# Create a shared $HOME directory
RUN useradd -m -s /bin/bash -G users qsiprep
WORKDIR /home/qsiprep

# Unless otherwise specified each process should only use one thread - nipype
# will handle parallelization
ENV \
    HOME="/home/qsiprep" \
    MKL_NUM_THREADS=1 \
    OMP_NUM_THREADS=1 \
    MRTRIX_NTHREADS=1 \
    KMP_WARNINGS=0 \
    CRN_SHARED_DATA=/niworkflows_data \
    IS_DOCKER_8395080871=1 \
    ARTHOME="/opt/art" \
    DIPY_HOME=/home/qsiprep/.dipy \
    QTDIR=$QT_BASE_DIR \
    PATH=$QT_BASE_DIR/bin:$PATH \
    LD_LIBRARY_PATH=$QT_BASE_DIR/lib/x86_64-linux-gnu:$QT_BASE_DIR/lib:$LD_LIBRARY_PATH \
    PKG_CONFIG_PATH=$QT_BASE_DIR/lib/pkgconfig:$PKG_CONFIG_PATH

WORKDIR /root/

# Precaching atlases
ADD docker/scripts/get_templates.sh get_templates.sh
RUN mkdir $CRN_SHARED_DATA && \
    /root/get_templates.sh && \
    chmod -R a+rX $CRN_SHARED_DATA

RUN ln -s /opt/fsl-6.0.5.1/bin/eddy_cuda10.2 /opt/fsl-6.0.5.1/bin/eddy_cuda
# Make it ok for singularity on CentOS
RUN strip --remove-section=.note.ABI-tag /opt/qt512/lib/libQt5Core.so.5.12.8 \
    && ldconfig

# Download the atlases
ENV QSIRECON_ATLAS /atlas/qsirecon_atlases
RUN bash -c \
    'mkdir /atlas \
    && cd  /atlas \
    && wget -nv https://upenn.box.com/shared/static/40f2m6dzzd8co5jx3cxpgct3zkkwm5d3.xz \
    && tar xvfJm 40f2m6dzzd8co5jx3cxpgct3zkkwm5d3.xz \
    && rm 40f2m6dzzd8co5jx3cxpgct3zkkwm5d3.xz'

# Make singularity mount directories
RUN  mkdir -p /sngl/data \
  && mkdir /sngl/qsiprep-output \
  && mkdir /sngl/out \
  && mkdir /sngl/scratch \
  && mkdir /sngl/spec \
  && mkdir /sngl/eddy \
  && mkdir /sngl/filter \
  && chmod a+rwx /sngl/*
