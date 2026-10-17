#!/usr/bin/env bash
# Project 02 cleanup - load balancer pieces first, then compute, then network
set -uo pipefail
cd "$(dirname "$0")"
source ../config.sh
VPC=lb-vpc

gcloud compute forwarding-rules delete web-fr --global --quiet
gcloud compute addresses delete web-ip --global --quiet
gcloud compute target-http-proxies delete web-proxy --quiet
gcloud compute url-maps delete web-map --quiet
gcloud compute backend-services delete web-backend --global --quiet
gcloud compute instance-groups managed delete web-mig --region="$REGION" --quiet
gcloud compute health-checks delete web-hc --quiet
gcloud compute instance-templates delete web-template --quiet
gcloud compute routers nats delete lb-nat --router=lb-router --region="$REGION" --quiet
gcloud compute routers delete lb-router --region="$REGION" --quiet
gcloud compute firewall-rules delete "$VPC"-allow-health-check "$VPC"-allow-iap-ssh --quiet
gcloud compute networks subnets delete lb-subnet --region="$REGION" --quiet
gcloud compute networks delete "$VPC" --quiet
echo "Project 02 resources deleted."
