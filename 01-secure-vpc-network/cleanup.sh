#!/usr/bin/env bash
# Project 01 cleanup - deletes in reverse dependency order
set -uo pipefail
cd "$(dirname "$0")"
source ../config.sh
VPC=prod-vpc

gcloud compute instances delete web-vm app-vm --zone="$ZONE" --quiet
gcloud compute routers nats delete nat-config --router=nat-router --region="$REGION" --quiet
gcloud compute routers delete nat-router --region="$REGION" --quiet
gcloud compute firewall-rules delete "$VPC"-allow-iap-ssh "$VPC"-allow-http "$VPC"-allow-web-to-app --quiet
gcloud compute networks subnets delete web-subnet app-subnet --region="$REGION" --quiet
gcloud compute networks delete "$VPC" --quiet
echo "Project 01 resources deleted."
