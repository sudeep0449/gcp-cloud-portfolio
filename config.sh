#!/usr/bin/env bash
# Shared settings for every project. Source this file; do not run it directly.
# Usage inside a project folder:  source ../config.sh

export PROJECT_ID="$(gcloud config get-value project 2>/dev/null)"
export REGION="${REGION:-australia-southeast1}"      # Sydney
export ZONE="${ZONE:-australia-southeast1-a}"
export MACHINE_TYPE="${MACHINE_TYPE:-e2-micro}"      # smallest general-purpose type

if [[ -z "${PROJECT_ID}" ]]; then
  echo "No active project. Run: gcloud config set project YOUR_PROJECT_ID" >&2
  return 1 2>/dev/null || exit 1
fi

gcloud config set compute/region "${REGION}" >/dev/null
gcloud config set compute/zone "${ZONE}" >/dev/null
echo "Project: ${PROJECT_ID} | Region: ${REGION} | Zone: ${ZONE}"
