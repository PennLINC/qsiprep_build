ARG TAG_FSL
ARG TAG_FREESURFER
ARG TAG_ANTS
ARG TAG_MRTRIX3
ARG TAG_3TISSUE
ARG TAG_DSISTUDIO
ARG TAG_MICROMAMBA
ARG TAG_AFNI
ARG TAG_TORTOISE
ARG TAG_TORTOISECUDA
ARG TAG_SYNB0

# TO include FSL set --build-arg FSL_BUILD=build_fsl
# To skip it set --build-arg FSL_BUILD=no_fsl
ARG FSL_BUILD

# COPY can't handle variables, so here we go
FROM pennlinc/qsiprep-fsl:${TAG_FSL} as build_fsl
FROM pennlinc/qsiprep-freesurfer:${TAG_FREESURFER} as build_freesurfer
FROM pennlinc/qsiprep-ants:${TAG_ANTS} as build_ants
FROM pennlinc/qsiprep-mrtrix3:${TAG_MRTRIX3} as build_mrtrix3
FROM pennlinc/qsiprep-3tissue:${TAG_3TISSUE} as build_3tissue
FROM pennlinc/qsiprep-dsistudio:${TAG_DSISTUDIO} as build_dsistudio
FROM pennlinc/qsiprep-micromamba:${TAG_MICROMAMBA} as build_micromamba
FROM pennlinc/qsiprep-afni:${TAG_AFNI} as build_afni
FROM pennlinc/qsiprep-drbuddi:${TAG_TORTOISE} as build_tortoise
FROM pennlinc/qsiprep-drbuddicuda:${TAG_TORTOISECUDA} as build_tortoisecuda
FROM pennlinc/qsiprep-synb0:${TAG_SYNB0} as build_synb0
FROM pennlinc/atlaspack:0.1.0 as atlaspack
FROM nvidia/cuda:12.2.2-runtime-ubuntu22.04 as ubuntu

# Make a dummy fsl image containing no FSL
FROM ubuntu as no_fsl
RUN mkdir -p /opt/conda/envs/fslqsiprep/bin \
    && touch /opt/conda/envs/fslqsiprep/bin/eddy_cuda10.2

FROM ${FSL_BUILD} as this-fsl

FROM ubuntu
## FSL
COPY --from=this-fsl /opt/conda/envs/fslqsiprep /opt/conda/envs/fslqsiprep
ENV FSLDIR="/opt/conda/envs/fslqsiprep" \
    FSLOUTPUTTYPE="NIFTI_GZ" \
    FSLMULTIFILEQUIT="TRUE" \
    FSLLOCKDIR="" \
    FSLMACHINELIST="" \
    FSLREMOTECALL="" \
    FSLGECUDAQ="cuda.q" \
    PATH="/opt/conda/envs/fslqsiprep/bin:$PATH" \
    FSL_DEPS="libquadmath0" \
    FSL_BUILD="${FSL_BUILD}"

## ANTs
COPY --from=build_ants /opt/ants /opt/ants
ENV ANTSPATH="/opt/ants/bin" \
    LD_LIBRARY_PATH="/opt/ants/lib:$LD_LIBRARY_PATH" \
    PATH="$PATH:/opt/ants/bin" \
    ANTS_DEPS="zlib1g-dev"

## DSI Studio
ENV PATH="$PATH:/opt/dsi-studio-cpu" \
    DSI_STUDIO_DEPS="qt6-base-dev libqt6charts6-dev"

## MRtrix3
COPY --from=build_mrtrix3 /opt/mrtrix3-latest /opt/mrtrix3-latest
## MRtrix3-3Tissue
COPY --from=build_3tissue /opt/3Tissue /opt/3Tissue
ENV PATH="$PATH:/opt/mrtrix3-latest/bin:/opt/3Tissue/bin" \
    MRTRIX3_DEPS="bzip2 ca-certificates curl libpng16-16 libblas3 liblapack3"

## Freesurfer
COPY --from=build_freesurfer /opt/freesurfer /opt/freesurfer
# Simulate SetUpFreeSurfer.sh
ENV FSL_DIR="/opt/conda/envs/fslqsiprep" \
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
RUN chmod a+rx /opt/freesurfer/bin/mri_synthseg /opt/freesurfer/bin/mri_synthstrip

# SynB0-DISCO
COPY --from=build_synb0 /opt/synb0 /opt/synb0
ENV SYNB0_ATLASES=/opt/synb0/atlases

## AFNI
COPY --from=build_afni /opt/afni-latest /opt/afni-latest
ENV PATH="$PATH:/opt/afni-latest" \
    AFNI_INSTALLDIR=/opt/afni-latest \
    AFNI_IMSAVE_WARNINGS=NO

## TORTOISE
COPY --from=build_tortoise /src/TORTOISEV4/bin /src/TORTOISEV4/bin
COPY --from=build_tortoise /src/TORTOISEV4/settings /src/TORTOISEV4/settings
COPY --from=build_tortoisecuda /src/TORTOISEV4/bin/*cuda /src/TORTOISEV4/bin/
ENV PATH="$PATH:/src/TORTOISEV4/bin" \
    TORTOISE_DEPS="fftw3"

    # Create a shared $HOME directory
RUN useradd -m -s /bin/bash -G users qsiprep
WORKDIR /home/qsiprep

## Python, compiled dependencies
COPY --from=build_micromamba /opt/conda/envs/qsiprep /opt/conda/envs/qsiprep
COPY --from=build_micromamba /home/qsiprep/.dipy /home/qsiprep/.dipy
ENV PATH="/opt/conda/envs/qsiprep/bin:$PATH"

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
           libboost-all-dev \
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
    && curl -sSL --retry 5 -o /tmp/libxp6.deb https://upenn.box.com/shared/static/reyyundn0l3guvjzghrrv6t4w6md2tjd.deb \
    && dpkg -i /tmp/libxp6.deb \
    && rm /tmp/libxp6.deb \
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
    curl -sL https://deb.nodesource.com/setup_16.x | bash - && \
    apt-get install -y --no-install-recommends \
      nodejs && \
    apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN npm install -g svgo \
    && npm install -g bids-validator@1.8.4

# Install latest pandoc
RUN curl -o pandoc-2.2.2.1-1-amd64.deb -sSL "https://github.com/jgm/pandoc/releases/download/2.2.2.1/pandoc-2.2.2.1-1-amd64.deb" && \
    dpkg -i pandoc-2.2.2.1-1-amd64.deb && \
    rm pandoc-2.2.2.1-1-amd64.deb

# Install qt6
RUN apt-get update \
    && apt install -y --no-install-recommends \
    ${DSI_STUDIO_DEPS} ${MRTRIX3_DEPS} ${TORTOISE_DEPS} wget git binutils \
    && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
COPY --from=build_dsistudio /opt/dsi-studio-cpu /opt/dsi-studio-cpu

# Install gcc-9
RUN add-apt-repository ppa:ubuntu-toolchain-r/test \
    && apt-get update \
    && apt-get install -y --no-install-recommends libstdc++6 \
    && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Install ACPC-detect
WORKDIR /opt/art
ENV PATH="/opt/art/bin:$PATH"
RUN cd /opt/art \
    && curl -fsSL https://osf.io/73h5s/download \
    | tar xz --strip-components 1

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
    LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:/opt/conda/envs/qsiprep/lib/python3.10/site-packages/nvidia/cudnn/lib:/opt/freesurfer/lib

WORKDIR /root/

COPY scripts/fetch_templates.py fetch_templates.py
RUN python fetch_templates.py && \
    rm fetch_templates.py && \
    find $HOME/.cache/templateflow -type d -exec chmod go=u {} + && \
    find $HOME/.cache/templateflow -type f -exec chmod go=u {} +

# Make it ok for singularity on CentOS
RUN for lib in /usr/lib/x86_64-linux-gnu/libQt?Core.so.* ; do \
      strip --remove-section=.note.ABI-tag "$lib" 2>/dev/null || true ; \
    done && ldconfig

# Make singularity mount directories
RUN  mkdir -p /sngl/data \
  && mkdir /sngl/qsiprep-output \
  && mkdir /sngl/out \
  && mkdir /sngl/scratch \
  && mkdir /sngl/eddy \
  && mkdir /sngl/filter \
  && chmod a+rwx /sngl/*
