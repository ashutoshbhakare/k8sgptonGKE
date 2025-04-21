#!/bin/bash

# Fetch zone and project from GCP metadata
zone=$(curl -s -H "Metadata-Flavor: Google" \
"http://metadata.google.internal/computeMetadata/v1/instance/zone" | awk -F/ '{print $NF}')
export zone="$zone"

export project=$(curl -s -H "Metadata-Flavor: Google" \
  http://metadata.google.internal/computeMetadata/v1/project/project-id)

# Install GKE plugin and kubectl
sudo apt-get update
sudo apt-get install -y google-cloud-cli-gke-gcloud-auth-plugin kubectl

echo "=============================================================================="
echo "[+] Installing k8sgpt CLI..."
echo "=============================================================================="

# Install k8sgpt CLI directly (no Helm)
curl -LO https://github.com/k8sgpt-ai/k8sgpt/releases/download/v0.4.1/k8sgpt_amd64.deb
sudo dpkg -i k8sgpt_amd64.deb

# Authenticate with Google Gemini
echo "=============================================================================="
echo "Enter the API Key: "
read -r key
echo "=============================================================================="
k8sgpt auth add --backend google --model="gemini-2.0-flash" --password="$key"

# Wait for the cluster to be ready
echo "=============================================================================="
echo "[+] Waiting for GKE cluster 'lab-cluster' to be ready..."
echo "=============================================================================="
while true; do
  cluster_status=$(gcloud container clusters describe lab-cluster --zone="$zone" --project="$project" --format="value(status)" 2>/dev/null)

  if [[ "$cluster_status" == "RUNNING" ]]; then
echo "=============================================================================="
    echo "[+] Cluster 'lab-cluster' is now running!"
echo "=============================================================================="
    break
  else
echo "=============================================================================="
    echo "[-] Cluster not ready yet (status: $cluster_status). Retrying in 30 seconds..."
echo "=============================================================================="
    sleep 30
  fi
done

# Get credentials to access the cluster
echo "=============================================================================="
echo "[+] Setting up credentials for GKE cluster..."
echo "=============================================================================="
gcloud container clusters get-credentials lab-cluster --zone "$zone" --project "$project"

echo "=============================================================================="
echo "Ready to use k8sgpt CLI with your GKE cluster."
echo "=============================================================================="
