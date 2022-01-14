#!/bin/bash
export DOCKER_BUILDKIT=1

TAG=22.1.0
docker build \
    -t pennbbl/qsiprep-ants:${TAG} \
    -f Dockerfile_ANTs .

docker build \
    -t pennbbl/qsiprep-fsl:${TAG} \
    -f Dockerfile_FSL .

docker build \
    -t pennbbl/qsiprep-mrtrix3:${TAG} \
    -f Dockerfile_MRtrix3 .

