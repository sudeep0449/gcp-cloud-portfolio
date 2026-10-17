#! /bin/bash
# Runs on every instance the managed instance group creates
apt-get update
apt-get install -y nginx
ZONE=$(curl -s -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/zone | awk -F/ '{print $NF}')
cat > /var/www/html/index.html <<EOF
<html><body style="font-family:Arial;text-align:center;margin-top:60px">
<h1>Project 02 - Load-balanced web app</h1>
<p>Served by: <b>$(hostname)</b></p>
<p>Zone: <b>${ZONE}</b></p>
</body></html>
EOF
