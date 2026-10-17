#!/usr/bin/env bash
# Project 05 cleanup. The budget is kept on purpose - it protects every project.
set -uo pipefail
cd "$(dirname "$0")"
source ../config.sh

for id in $(gcloud monitoring uptime list-configs --filter="displayName=mon-vm-http" --format="value(name)"); do
  gcloud monitoring uptime delete "$id" --quiet
done
for id in $(gcloud monitoring policies list --filter="displayName~'^mon-'" --format="value(name)"); do
  gcloud monitoring policies delete "$id" --quiet
done
gcloud compute instances delete mon-vm --zone="$ZONE" --quiet
gcloud compute firewall-rules delete mon-allow-http --quiet
echo "Project 05 resources deleted. Budget 'portfolio-budget' and the email channel were kept."
