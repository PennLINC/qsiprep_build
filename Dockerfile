ARG TAG_FSL
ARG TAG_FREESURFER
ARG TAG_ANTS
ARG TAG_MRTRIX3
ARG TAG_3TISSUE
ARG TAG_DSISTUDIO
ARG TAG_MINICONDA
ARG TAG_AFNI
ARG TAG_TORTOISE
ARG TAG_TORTOISECUDA

# TO include FSL set --build-arg FSL_BUILD=build_fsl
# To skip it set --build-arg FSL_BUILD=no_fsl
ARG FSL_BUILD

# COPY can't handle variables, so here we go
FROM pennbbl/qsiprep-fsl:${TAG_FSL} as build_fsl
FROM pennbbl/qsiprep-freesurfer:${TAG_FREESURFER} as build_freesurfer
FROM pennbbl/qsiprep-ants:${TAG_ANTS} as build_ants
FROM pennbbl/qsiprep-mrtrix3:${TAG_MRTRIX3} as build_mrtrix3
FROM pennbbl/qsiprep-3tissue:${TAG_3TISSUE} as build_3tissue
FROM pennbbl/qsiprep-dsistudio:${TAG_DSISTUDIO} as build_dsistudio
FROM pennbbl/qsiprep-miniconda:${TAG_MINICONDA} as build_miniconda
FROM pennbbl/qsiprep-afni:${TAG_AFNI} as build_afni
FROM pennbbl/qsiprep-drbuddi:${TAG_TORTOISE} as build_tortoise
FROM pennlinc/atlaspack:0.1.0 as atlaspack
FROM ubuntu:jammy-20240125 as ubuntu

# Make a dummy fsl image containing no FSL
FROM ubuntu as no_fsl
RUN mkdir -p /opt/conda/envs/fslqsiprep \
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
    PATH="$PATH:/opt/ants/bin" \
    ANTS_DEPS="zlib1g-dev"

## DSI Studio
ENV PATH="$PATH:/opt/dsi-studio/dsi_studio_64" \
    DSI_STUDIO_DEPS=""

## MRtrix3
COPY --from=build_mrtrix3 /opt/mrtrix3-latest /opt/mrtrix3-latest
## MRtrix3-3Tissue
COPY --from=build_3tissue /opt/3Tissue /opt/3Tissue
ENV PATH="$PATH:/opt/mrtrix3-latest/bin:/opt/3Tissue/bin" \
    MRTRIX3_DEPS="bzip2 ca-certificates curl libpng16-16 libblas3 liblapack3"

## Freesurfer
COPY --from=build_freesurfer /opt/freesurfer /opt/freesurfer
# Simulate SetUpFreeSurfer.sh
ENV FSL_DIR="/opt/fsl-6.0.7.9" \
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

## AFNI
COPY --from=build_afni /opt/afni-latest /opt/afni-latest
ENV PATH="$PATH:/opt/afni-latest" \
    AFNI_INSTALLDIR=/opt/afni-latest \
    AFNI_IMSAVE_WARNINGS=NO

## TORTOISE
COPY --from=build_tortoise /src/TORTOISEV4/bin /src/TORTOISEV4/bin
COPY --from=build_tortoise /src/TORTOISEV4/settings /src/TORTOISEV4/settings
COPY --from=build_tortoise /usr/local/boost176 /usr/local/boost176
ENV PATH="$PATH:/src/TORTOISEV4/bin" \
    TORTOISE_DEPS="libeigen3-dev fftw3 libfftw3-dev"

## Python, compiled dependencies
COPY --from=build_miniconda /usr/local/miniconda /usr/local/miniconda
COPY --from=build_miniconda /home/qsiprep/.dipy /home/qsiprep/.dipy
ENV PATH="/usr/local/miniconda/bin:$PATH"

# Some baseline tools; bc is needed for FreeSurfer, so don't drop it
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
                    bc \
                    ca-certificates \
                    curl \
                    git \
                    gnupg \
                    lsb-release \
                    netbase \
                    xvfb && \
    apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Configure PPAs for libpng12 and libxp6
RUN GNUPGHOME=/tmp gpg --keyserver hkps://keyserver.ubuntu.com --no-default-keyring --keyring /usr/share/keyrings/linuxuprising.gpg --recv 0xEA8CACC073C3DB2A \
    && GNUPGHOME=/tmp gpg --keyserver hkps://keyserver.ubuntu.com --no-default-keyring --keyring /usr/share/keyrings/zeehio.gpg --recv 0xA1301338A3A48C4A \
    && echo "deb [signed-by=/usr/share/keyrings/linuxuprising.gpg] https://ppa.launchpadcontent.net/linuxuprising/libpng12/ubuntu jammy main" > /etc/apt/sources.list.d/linuxuprising.list \
    && echo "deb [signed-by=/usr/share/keyrings/zeehio.gpg] https://ppa.launchpadcontent.net/zeehio/libxp/ubuntu jammy main" > /etc/apt/sources.list.d/zeehio.list

# Dependencies for AFNI; requires a discontinued multiarch-support package from bionic (18.04)
RUN apt-get update -qq \
    && apt-get install -y -q --no-install-recommends \
           ed \
           gsl-bin \
           libglib2.0-0 \
           libglu1-mesa-dev \
           libglw1-mesa \
           libgomp1 \
           libjpeg62 \
           libpng12-0 \
           libxm4 \
           libxp6 \
           netpbm \
           tcsh \
           wget \
           xfonts-base \
           xvfb \
    && curl -sSL --retry 5 -o /tmp/multiarch.deb http://archive.ubuntu.com/ubuntu/pool/main/g/glibc/multiarch-support_2.27-3ubuntu1.5_amd64.deb \
    && dpkg -i /tmp/multiarch.deb \
    && rm /tmp/multiarch.deb \
    && apt-get install -f \
    && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
    && gsl2_path="$(find / -name 'libgsl.so.19' || printf '')" \
    && if [ -n "$gsl2_path" ]; then \
         ln -sfv "$gsl2_path" "$(dirname $gsl2_path)/libgsl.so.0"; \
    fi \
    && ldconfig

RUN echo "Downloading Convert3D ..." \
    && mkdir -p /opt/convert3d-nightly \
    && curl -fsSL --retry 5 https://sourceforge.net/projects/c3d/files/c3d/Nightly/c3d-nightly-Linux-x86_64.tar.gz/download \
    | tar -xz -C /opt/convert3d-nightly --strip-components 1 \
    --exclude "c3d-1.0.0-Linux-x86_64/lib" \
    --exclude "c3d-1.0.0-Linux-x86_64/share" \
    --exclude "c3d-1.0.0-Linux-x86_64/bin/c3d_gui"
ENV C3DPATH="/opt/convert3d-nightly" \
    PATH="/opt/convert3d-nightly/bin:$PATH"


# Install latest pandoc
RUN curl -o pandoc-2.2.2.1-1-amd64.deb -sSL "https://github.com/jgm/pandoc/releases/download/2.2.2.1/pandoc-2.2.2.1-1-amd64.deb" && \
    dpkg -i pandoc-2.2.2.1-1-amd64.deb && \
    rm pandoc-2.2.2.1-1-amd64.deb

COPY --from=build_dsistudio /opt/dsi-studio /opt/dsi-studio


# Install ACPC-detect
WORKDIR /opt/art
ENV PATH="/opt/art/bin:$PATH"
RUN cd /opt/art \
    && curl -fsSL https://osf.io/73h5s/download \
    | tar xz --strip-components 1

# Download atlases from AtlasPack
RUN mkdir /AtlasPack
COPY --from=atlaspack /AtlasPack/tpl-fsLR_*.dlabel.nii /AtlasPack/
COPY --from=atlaspack /AtlasPack/tpl-MNI152NLin6Asym_*.nii.gz /AtlasPack/
COPY --from=atlaspack /AtlasPack/tpl-MNI152NLin2009cAsym_*.nii.gz /AtlasPack/
COPY --from=atlaspack /AtlasPack/atlas-4S*.tsv /AtlasPack/
COPY --from=atlaspack /AtlasPack/*.json /AtlasPack/

# Create a shared $HOME directory
RUN useradd -m -s /bin/bash -G users qsiprep
WORKDIR /home/qsiprep

# Unless otherwise specified each process should only use one thread - nipype
# will handle parallelization
ENV DEBIAN_FRONTEND="noninteractive" \
    LANG="en_US.UTF-8" \
    LC_ALL="en_US.UTF-8" \
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
    PKG_CONFIG_PATH=$QT_BASE_DIR/lib/pkgconfig:$PKG_CONFIG_PATH

# RUN if [ $FSL_BUILD == "build_fsl" ]; then \
#     mkdir -p /tmp/src \
#     && cd /tmp/src \
#     && wget https://git.fmrib.ox.ac.uk/matteob/eddy_qc_release/-/archive/master/eddy_qc_release-master.zip \
#     && unzip eddy_qc_release-master.zip

# Precaching atlases
WORKDIR /root
ADD docker/scripts/get_templates.sh get_templates.sh
RUN mkdir $CRN_SHARED_DATA && \
    /root/get_templates.sh && \
    chmod -R a+rX $CRN_SHARED_DATA

#RUN ln -s /opt/fsl-6.0.7.9/bin/eddy_cuda10.2 /opt/fsl-6.0.7.9/bin/eddy_cuda
# Make it ok for singularity on CentOS
# RUN strip --remove-section=.note.ABI-tag /opt/qt512/lib/libQt5Core.so.5.12.8 \
#     && ldconfig

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

ENV LD_LIBRARY_PATH="/opt/fsl-6.0.7.9/lib:/opt/ants/lib:$LD_LIBRARY_PATH"