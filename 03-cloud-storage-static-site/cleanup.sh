#!/usr/bin/env bash
# Project 03 cleanup - removes all object versions, then the bucket
set -uo pipefail
cd "$(dirname "$0")"
source ../config.sh
BUCKET="${PROJECT_ID}-static-site"

gcloud storage rm --recursive --all-versions "gs://${BUCKET}/**"
gcloud storage buckets delete "gs://${BUCKET}" --quiet
echo "Project 03 resources deleted."
