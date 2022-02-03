#!/bin/bash

# Set up the environment for the main build
BUILD_TAG=latest
if [[ -n "${CIRCLE_TAG}" ]]; then
    BUILD_TAG="${CIRCLE_TAG}"
fi
export BUILD_TAG

# Versions of the components
export TAG_FSL=22.2.0
export TAG_FREESURFER=22.2.0
export TAG_ANTS=22.1.0
export TAG_MRTRIX3=22.1.0
export TAG_3TISSUE=22.1.0
export TAG_DSISTUDIO=22.1.0
export TAG_MINICONDA=22.1.0
export TAG_AFNI=22.2.0


do_build() {

    DOCKER_BUILDKIT=1 \
    BUILDKIT_PROGRESS=plain \
    docker build -t \
        pennbbl/qsiprep_build:${BUILD_TAG} \
        --build-arg TAG_FSL=${TAG_FSL} \
        --build-arg TAG_FREESURFER=${TAG_FREESURFER} \
        --build-arg TAG_ANTS=${TAG_ANTS} \
        --build-arg TAG_MRTRIX3=${TAG_MRTRIX3} \
        --build-arg TAG_3TISSUE=${TAG_3TISSUE} \
        --build-arg TAG_DSISTUDIO=${TAG_DSISTUDIO} \
        --build-arg TAG_MINICONDA=${TAG_MINICONDA} \
        --build-arg TAG_AFNI=${TAG_AFNI} \
        .

}
