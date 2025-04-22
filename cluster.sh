#!/bin/bash

echo "=============================================================================="
echo "Enter Your Zone in which the GKE Cluster and Instance will launched: "
echo "=============================================================================="
read zone
export zone=$zone


username=$(gcloud auth list --format="value(account)" | cut -d'@' -f1)
export username

echo "=============================================================================="
echo "[+] enabling API's......"
echo "=============================================================================="
gcloud services enable container.googleapis.com
gcloud services enable compute.googleapis.com

echo "=============================================================================="
echo "[+] Creating VM..."
echo "=============================================================================="
gcloud compute instances create my-vm \
  --zone=$zone \
  --machine-type=e2-medium \
  --image-family=debian-11 \
  --image-project=debian-cloud \
  --scopes=https://www.googleapis.com/auth/cloud-platform \
  --quiet

sleep 10

if [ ! -f ~/.ssh/id_rsa ]; then
    echo "=============================================================================="
    echo "[+] Generating SSH key..."
    echo "=============================================================================="
    ssh-keygen -t rsa -f ~/.ssh/id_rsa -q -N ""
fi
    echo "=============================================================================="
    echo "[+] Adding SSH key to instance metadata..."
    echo "=============================================================================="
gcloud compute instances add-metadata my-vm \
  --metadata-from-file ssh-keys=<(echo "$username:$(cat ~/.ssh/id_rsa.pub)") \
  --zone=$zone \
  --quiet

sleep 10

echo "=============================================================================="
echo "[+] Copying instance.sh to VM..."
echo "=============================================================================="
gcloud compute scp ./instannce.sh $username@my-vm:/home/$username --zone=$zone --quiet

echo "=============================================================================="
echo "[+] Creating GKE cluster in the background..."
echo "=============================================================================="

nohup gcloud container clusters create lab-cluster \
  --machine-type=e2-medium \
  --zone="$zone" \
  --num-nodes=2 \
  --quiet > cluster-create.log 2>&1 &


gcloud compute ssh my-vm --zone=$zone
