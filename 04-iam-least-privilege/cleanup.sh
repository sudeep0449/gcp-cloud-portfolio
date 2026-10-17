#!/usr/bin/env bash
# Project 04 cleanup
set -uo pipefail
cd "$(dirname "$0")"
source ../config.sh
SA_EMAIL="backup-writer@${PROJECT_ID}.iam.gserviceaccount.com"
BUCKET="${PROJECT_ID}-backups"

gcloud compute instances delete iam-test-vm --zone="$ZONE" --quiet
gcloud storage rm --recursive "gs://${BUCKET}/**"
gcloud storage buckets delete "gs://${BUCKET}" --quiet
gcloud iam roles delete vmOperator --project="$PROJECT_ID" --quiet
gcloud iam service-accounts delete "$SA_EMAIL" --quiet
echo "Project 04 resources deleted. (Deleted custom roles are kept for 7 days before permanent removal.)"
