#!/bin/bash

echo "Enter your GCP zone (same as used before): "
read zone
export zone=$zone

# Get current project ID
project=$(gcloud config get-value project)
export project

# Get username
username=$(gcloud auth list --format="value(account)" | awk -F@ '{print $1}')

echo "[🗑] Deleting Compute Engine VM 'my-vm'..."
gcloud compute instances delete my-vm \
  --zone="$zone" \
  --quiet

echo "[⏳] Starting background deletion of GKE cluster 'lab-cluster'..."
nohup gcloud container clusters delete lab-cluster \
  --zone="$zone" \
  --quiet > gke-delete.log 2>&1 &

echo "[✅] VM deletion done. GKE cluster is being deleted in the background."
echo "Check 'gke-delete.log' later to verify cluster deletion."
