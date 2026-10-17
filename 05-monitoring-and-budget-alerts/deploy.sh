#!/usr/bin/env bash
# Project 05 - Observability and cost control:
# Ops Agent on a VM, an HTTP uptime check, an email alert channel and a billing budget
set -euo pipefail
cd "$(dirname "$0")"
source ../config.sh

ALERT_EMAIL="${ALERT_EMAIL:?Set ALERT_EMAIL first, e.g. export ALERT_EMAIL=you@example.com}"
BUDGET_AMOUNT="${BUDGET_AMOUNT:-10}"   # number only; currency is read from the billing account

echo "== 1. Monitored web VM with the Ops Agent (memory, disk and nginx metrics + logs) =="
gcloud compute firewall-rules create mon-allow-http \
  --network=default --direction=INGRESS --action=ALLOW --rules=tcp:80 \
  --source-ranges=0.0.0.0/0 --target-tags=mon-web
gcloud compute instances create mon-vm \
  --zone="$ZONE" --machine-type=e2-small --tags=mon-web \
  --image-family=debian-12 --image-project=debian-cloud \
  --metadata=startup-script='#! /bin/bash
apt-get update && apt-get install -y nginx
curl -sSO https://dl.google.com/cloudagents/add-google-cloud-ops-agent-repo.sh
bash add-google-cloud-ops-agent-repo.sh --also-install'

VM_IP=$(gcloud compute instances describe mon-vm --zone="$ZONE" \
  --format='get(networkInterfaces[0].accessConfigs[0].natIP)')

echo "== 2. Uptime check against the VM (probed from several regions) =="
gcloud monitoring uptime create mon-vm-http \
  --resource-type=uptime-url \
  --resource-labels=host="$VM_IP",project_id="$PROJECT_ID" \
  --protocol=http --port=80 --path=/ --period=1

echo "== 3. Email notification channel (beta command; pre-installed in Cloud Shell) =="
gcloud beta monitoring channels create \
  --display-name="Cloud alerts email" --type=email \
  --channel-labels=email_address="$ALERT_EMAIL"

echo "== 4. Billing budget with 50 / 90 / 100 % thresholds =="
BILLING_ACCOUNT=$(gcloud billing projects describe "$PROJECT_ID" --format='value(billingAccountName)' | sed 's|billingAccounts/||')
CURRENCY=$(gcloud billing accounts describe "$BILLING_ACCOUNT" --format='value(currencyCode)' 2>/dev/null || true)
CURRENCY="${BUDGET_CURRENCY:-${CURRENCY:-USD}}"   # override with export BUDGET_CURRENCY=AUD if needed
gcloud billing budgets create \
  --billing-account="$BILLING_ACCOUNT" \
  --display-name="portfolio-budget" \
  --budget-amount="${BUDGET_AMOUNT}${CURRENCY}" \
  --filter-projects="projects/${PROJECT_ID}" \
  --threshold-rule=percent=0.5 \
  --threshold-rule=percent=0.9 \
  --threshold-rule=percent=1.0 \
  --threshold-rule=percent=1.0,basis=forecasted-spend

echo
echo "Now create the two alert policies in the console (steps in README.md)."
echo "VM: http://$VM_IP"
