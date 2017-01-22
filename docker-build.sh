#!/bin/bash
set -eau
SCRIPT=`readlink -f "$0"`
SCRIPT_DIR=`dirname "${SCRIPT}"`
OS="$1"
DOCKERFILE="${SCRIPT_DIR}/docker/$OS".dockerfile

if [ ! -f "${DOCKERFILE}" ]; then
	echo "Cannot find '${DOCKERFILE}', specify a valid OS name"
	exit 1
fi

IMAGE=nvim-build-$OS
echo -e "$(eval "echo -e \"`<${DOCKERFILE}`\"")" | docker build -t $IMAGE -

docker run \
	--rm \
	-v "${SCRIPT_DIR}:/build" \
	-w /build \
	-e BUILD_NAME="build-$OS" \
	$IMAGE
