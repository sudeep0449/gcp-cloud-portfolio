#!/usr/bin/env bash
# Project 03 - Static website on Cloud Storage with versioning and lifecycle management
set -euo pipefail
cd "$(dirname "$0")"
source ../config.sh

# Bucket names are global, so include the project ID to keep it unique
BUCKET="${PROJECT_ID}-static-site"

echo "== 1. Bucket with uniform bucket-level access =="
gcloud storage buckets create "gs://${BUCKET}" \
  --location="$REGION" --default-storage-class=STANDARD \
  --uniform-bucket-level-access

echo "== 2. Website configuration =="
gcloud storage buckets update "gs://${BUCKET}" \
  --web-main-page-suffix=index.html --web-error-page=404.html

echo "== 3. Versioning + lifecycle rules =="
gcloud storage buckets update "gs://${BUCKET}" --versioning
gcloud storage buckets update "gs://${BUCKET}" --lifecycle-file=lifecycle.json

echo "== 4. Upload site with a short cache time =="
gcloud storage cp site/* "gs://${BUCKET}/" --cache-control="public, max-age=60"

echo "== 5. Public read on objects only (no list, no write) =="
gcloud storage buckets add-iam-policy-binding "gs://${BUCKET}" \
  --member=allUsers --role=roles/storage.objectViewer

echo
echo "Site: https://storage.googleapis.com/${BUCKET}/index.html"
