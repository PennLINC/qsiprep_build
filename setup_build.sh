#!/bin/bash

# Set up the environment for the main build
BUILD_TAG=latest
if [[ -n "${CIRCLE_TAG}" ]]; then
    BUILD_TAG="${CIRCLE_TAG}"
fi
export BUILD_TAG

# Versions of the components
export TAG_FSL=22.9.0
export TAG_FREESURFER=23.3.0
export TAG_ANTS=23.2.0
export TAG_MRTRIX3=22.1.0
export TAG_3TISSUE=22.1.0
export TAG_DSISTUDIO=23.7.1
export TAG_MINICONDA=24.1.0
export TAG_AFNI=23.3.2
export TAG_TORTOISE=23.5.5

echo "Settings:"
echo "----------"
echo ""
echo "BUILD_TAG=${BUILD_TAG}"
echo "TAG_FSL=${TAG_FSL}"
echo "TAG_FREESURFER=${TAG_FREESURFER}"
echo "TAG_ANTS=${TAG_ANTS}"
echo "TAG_MRTRIX3=${TAG_MRTRIX3}"
echo "TAG_3TISSUE=${TAG_3TISSUE}"
echo "TAG_DSISTUDIO=${TAG_DSISTUDIO}"
echo "TAG_MINICONDA=${TAG_MINICONDA}"
echo "TAG_AFNI=${TAG_AFNI}"
echo "TAG_TORTOISE=${TAG_TORTOISE}"


do_build() {

    INCLUDE_FSL=$1

    THIS_TAG=${BUILD_TAG}
    if [ "${INCLUDE_FSL}" == "no_fsl" ]; then
        THIS_TAG=${BUILD_TAG}-nofsl
    fi

    DOCKER_BUILDKIT=1 \
    BUILDKIT_PROGRESS=plain \
    docker build -t \
        pennbbl/qsiprep_build:${THIS_TAG} \
        --build-arg TAG_FSL=${TAG_FSL} \
        --build-arg TAG_FREESURFER=${TAG_FREESURFER} \
        --build-arg TAG_ANTS=${TAG_ANTS} \
        --build-arg TAG_MRTRIX3=${TAG_MRTRIX3} \
        --build-arg TAG_3TISSUE=${TAG_3TISSUE} \
        --build-arg TAG_DSISTUDIO=${TAG_DSISTUDIO} \
        --build-arg TAG_MINICONDA=${TAG_MINICONDA} \
        --build-arg TAG_AFNI=${TAG_AFNI} \
        --build-arg TAG_TORTOISE=${TAG_TORTOISE} \
        --build-arg FSL_BUILD=${INCLUDE_FSL} \
        .

}
