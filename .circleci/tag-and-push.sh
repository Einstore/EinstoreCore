#!/bin/sh
set -xeuo pipefail
IFS=$'\n\t'
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

ORIGINAL_TAG="$1"
MARK="${2:-""}"
IMAGE_NAME="einstore/einstore-core"

function tagAndPush {
    docker tag "${IMAGE_NAME}:${ORIGINAL_TAG}" "${IMAGE_NAME}:$1"
    docker push "${IMAGE_NAME}:$1"
}

if [ ! -z ${CIRCLE_BRANCH-} ]; then
    BRANCH_SLUG=$(echo ${CIRCLE_BRANCH} | sed -r s/[~\^]+//g | sed -r s/[^a-zA-Z0-9]+/-/g | sed -r "s/^-+\|-+$//g" | tr A-Z a-z)
    tagAndPush "dev.${BRANCH_SLUG}${MARK}"
    tagAndPush "dev.${BRANCH_SLUG}${MARK}.$CIRCLE_SHA1"
fi

if [ ! -z ${CIRCLE_TAG-} ]; then
    tagAndPush "${CIRCLE_TAG}${MARK}"
fi
