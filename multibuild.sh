#!/bin/bash
export DOCKER_BUILDKIT=1

TAG=22.1.0
docker build \
    -t pennbbl/qsiprep-ants:${TAG} \
    -f Dockerfile_ANTs .
docker push pennbbl/qsiprep-ants:${TAG}

docker build \
    -t pennbbl/qsiprep-fsl:${TAG} \
    -f Dockerfile_FSL .
docker push pennbbl/qsiprep-fsl:${TAG}

docker build \
    -t pennbbl/qsiprep-mrtrix3:${TAG} \
    -f Dockerfile_MRtrix3 .
docker push pennbbl/qsiprep-mrtrix3:${TAG}


docker build \
    -t pennbbl/qsiprep-3tissue:${TAG} \
    -f Dockerfile_3Tissue .
docker push pennbbl/qsiprep-3tissue:${TAG}

docker build \
    -t pennbbl/qsiprep-dsistudio:${TAG} \
    -f Dockerfile_DSIStudio .
docker push pennbbl/qsiprep-dsistudio:${TAG}

docker build \
    -t pennbbl/qsiprep-freesurfer:${TAG} \
    -f Dockerfile_FreeSurfer .
docker push pennbbl/qsiprep-freesurfer:${TAG}

docker build \
    -t pennbbl/qsiprep-afni:${TAG} \
    -f Dockerfile_AFNI .
docker push pennbbl/qsiprep-afni:${TAG}

docker build \
    -t pennbbl/qsiprep-miniconda:${TAG} \
    -f Dockerfile_Miniconda .
docker push pennbbl/qsiprep-miniconda:${TAG}

docker build \
    -t pennbbl/qsiprep_build:${TAG} \
    -f Dockerfile_multi .
