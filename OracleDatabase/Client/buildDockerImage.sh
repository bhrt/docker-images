#!/bin/bash -e
# 
# Since: April, 2016
# Author: gerald.venzl@oracle.com
# Description: Build script for building Oracle Database Docker images.
# 
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
# 
# Copyright (c) 2014-2019 Oracle and/or its affiliates. All rights reserved.
# 

usage() {
  cat << EOF

Usage: buildDockerImage.sh -v [version] [-o] [Docker build option]
Builds a Docker Image for Oracle Client.
  
Parameters:
   -v: version to build
       Choose one of: $(for i in $(ls -d */); do echo -n "${i%%/}  "; done)
   -o: passes on Docker build option

EOF

}

# Check Podman version
checkPodmanVersion() {
  # Get Podman version
  echo "Checking Podman version."
  PODMAN_VERSION=$(docker info --format '{{.host.BuildahVersion}}')
  # Remove dot in Podman version
  PODMAN_VERSION=${PODMAN_VERSION//./}

  if [ -z "$PODMAN_VERSION" ]; then
    exit 1;
  elif [ "$PODMAN_VERSION" -lt "${MIN_PODMAN_VERSION//./}" ]; then
    echo "Podman version is below the minimum required version $MIN_PODMAN_VERSION"
    echo "Please upgrade your Podman installation to proceed."
    exit 1;
  fi
}

# Check Docker version
checkDockerVersion() {
  # Get Docker Server version
  echo "Checking Docker version."
  DOCKER_VERSION=$(docker version --format '{{.Server.Version | printf "%.5s" }}'|| exit 0)
  # Remove dot in Docker version
  DOCKER_VERSION=${DOCKER_VERSION//./}

  if [ -z "$DOCKER_VERSION" ]; then
    # docker could be aliased to podman and errored out (https://github.com/containers/libpod/pull/4608)
    checkPodmanVersion
  elif [ "$DOCKER_VERSION" -lt "${MIN_DOCKER_VERSION//./}" ]; then
    echo "Docker version is below the minimum required version $MIN_DOCKER_VERSION"
    echo "Please upgrade your Docker installation to proceed."
    exit 1;
  fi;
}

##############
#### MAIN ####
##############

# Parameters
VERSION="12.2.0.1"
DOCKEROPS=""
MIN_DOCKER_VERSION="17.09"
MIN_PODMAN_VERSION="1.6.0"
DOCKERFILE="Dockerfile"

if [ "$#" -eq 0 ]; then
  usage;
  exit 1;
fi

while getopts "hv:o" optname; do
  case "$optname" in
    "h")
      usage
      exit 0;
      ;;
    "v")
      VERSION="$OPTARG"
      ;;
    "o")
      DOCKEROPS="$OPTARG"
      ;;
    "?")
      usage;
      exit 1;
      ;;
    *)
    # Should not occur
      echo "Unknown error while processing options inside buildDockerImage.sh"
      ;;
  esac
done

checkDockerVersion

# Which Dockerfile should be used?
if [ "$VERSION" == "12.1.0.2" ] || [ "$VERSION" == "11.2.0.2" ] || [ "$VERSION" == "18.4.0" ]; then
  DOCKERFILE="$DOCKERFILE"
fi;

# Oracle Database Image Name
IMAGE_NAME="wms/oracle/instantclient:$VERSION"

# Go into version folder
cd "$VERSION" || {
  echo "Could not find version directory '$VERSION'";
  exit 1;
}

echo "=========================="
echo "DOCKER info:"
docker info
echo "=========================="

# Proxy settings
PROXY_SETTINGS=""
if [ "${http_proxy}" != "" ]; then
  PROXY_SETTINGS="$PROXY_SETTINGS --build-arg http_proxy=${http_proxy}"
fi

if [ "${https_proxy}" != "" ]; then
  PROXY_SETTINGS="$PROXY_SETTINGS --build-arg https_proxy=${https_proxy}"
fi

if [ "${ftp_proxy}" != "" ]; then
  PROXY_SETTINGS="$PROXY_SETTINGS --build-arg ftp_proxy=${ftp_proxy}"
fi

if [ "${no_proxy}" != "" ]; then
  PROXY_SETTINGS="$PROXY_SETTINGS --build-arg no_proxy=${no_proxy}"
fi

if [ "$PROXY_SETTINGS" != "" ]; then
  echo "Proxy settings were found and will be used during the build."
fi

# ################## #
# BUILDING THE IMAGE #
# ################## #
echo "Building image '$IMAGE_NAME' ..."

# BUILD THE IMAGE (replace all environment variables)
BUILD_START=$(date '+%s')
echo "docker build --force-rm=true --no-cache=true $DOCKEROPS $PROXY_SETTINGS -t $IMAGE_NAME -f $DOCKERFILE ."
docker build --force-rm=true --no-cache=true \
       $DOCKEROPS $PROXY_SETTINGS \
       -t $IMAGE_NAME -f $DOCKERFILE . || {
  echo ""
  echo "ERROR: Oracle Client Docker Image was NOT successfully created."
  echo "ERROR: Check the output and correct any reported problems with the docker build operation."
  exit 1
}

# Remove dangling images (intermitten images with tag <none>)
yes | docker image prune > /dev/null

BUILD_END=$(date '+%s')
BUILD_ELAPSED=`expr $BUILD_END - $BUILD_START`

echo ""
echo ""

cat << EOF
  Oracle Client Docker Image version $VERSION is ready to be extended: 
    
    --> $IMAGE_NAME

  Build completed in $BUILD_ELAPSED seconds.
  
EOF

