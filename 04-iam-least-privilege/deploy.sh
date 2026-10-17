#!/usr/bin/env bash
# Project 04 - Least-privilege IAM: dedicated service account, bucket-scoped role, custom role
set -euo pipefail
cd "$(dirname "$0")"
source ../config.sh

SA_NAME=backup-writer
SA_EMAIL="${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"
BUCKET="${PROJECT_ID}-backups"

echo "== 1. Dedicated service account (instead of the Compute Engine default SA with Editor) =="
gcloud iam service-accounts create "$SA_NAME" \
  --display-name="Backup writer - can only create objects in the backups bucket"

echo "== 2. Backup bucket =="
gcloud storage buckets create "gs://${BUCKET}" --location="$REGION" --uniform-bucket-level-access

echo "== 3. Grant the role on the BUCKET, not the project =="
gcloud storage buckets add-iam-policy-binding "gs://${BUCKET}" \
  --member="serviceAccount:${SA_EMAIL}" --role=roles/storage.objectCreator

echo "== 4. Custom role: start/stop VMs only (for an operator who must not create or delete) =="
gcloud iam roles create vmOperator --project="$PROJECT_ID" \
  --title="VM Operator" \
  --description="Start, stop, reset and view VMs. Cannot create, delete or change them." \
  --permissions=compute.instances.get,compute.instances.list,compute.instances.start,compute.instances.stop,compute.instances.reset,compute.zones.list \
  --stage=GA

echo "== 5. Test VM running as the service account =="
gcloud compute instances create iam-test-vm \
  --zone="$ZONE" --machine-type="$MACHINE_TYPE" \
  --image-family=debian-12 --image-project=debian-cloud \
  --service-account="$SA_EMAIL" --scopes=cloud-platform

echo
echo "Done. Run the tests in README.md, then ./cleanup.sh"
