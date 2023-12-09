#!/bin/bash

# Vérifie si clusterctl est déjà installé
if command -v clusterctl &>/dev/null; then
    echo "clusterctl is already installed."
else
    # Télécharge clusterctl si ce n'est pas installé
    echo "clusterctl not found. Downloading..."
    curl -L https://github.com/kubernetes-sigs/cluster-api/releases/download/v1.6.0/clusterctl-linux-amd64 -o clusterctl
    sudo install -o root -g root -m 0755 clusterctl /usr/local/bin/clusterctl
fi

mkdir -p ~/.cluster-api
cp $(pwd)/clusterAPI/ipam-provider.yaml ~/.cluster-api/clusterctl.yaml

# The host for the Proxmox cluster
export PROXMOX_URL="https://proxmox-big.fredcorp.com:8006"
# The Proxmox token ID to access the remote Proxmox endpoint
export PROXMOX_TOKEN='root@pam!clusterapi'
# The secret associated with the token ID
# You may want to set this in `$XDG_CONFIG_HOME/cluster-api/clusterctl.yaml` so your password is not in
# bash history
export PROXMOX_SECRET="$1"
# Finally, initialize the management cluster
clusterctl init --infrastructure proxmox --ipam in-cluster
