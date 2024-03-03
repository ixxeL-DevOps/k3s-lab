#!/usr/bin/env bash

mgmt_cluster_name=k3d-mgmt-cluster
init_capi="$1"
DIR=$(pwd)

if command -v clusterctl &>/dev/null; then
  echo "clusterctl is already installed."
else
  echo "clusterctl not found. Downloading..."
  curl -L https://github.com/kubernetes-sigs/cluster-api/releases/download/v1.6.1/clusterctl-linux-amd64 -o clusterctl
  sudo install -o root -g root -m 0755 clusterctl /usr/local/bin/clusterctl
fi

if [[ "$init_capi" == "true" ]]
then
  clusterctl init --core cluster-api --infrastructure byoh --infrastructure docker --bootstrap k0smotron --control-plane k0smotron --config k0smotron-config.yaml 
fi

docker buildx build . -f Dockerfile.all -t byoh/node:v1
docker buildx build . -f Dockerfile -t byoh/node:e2e

for i in {1..2}
do
  echo "Creating docker container named host$i"
  docker run --detach \
             --tty \
             --hostname host$i \
             --name host$i \
             --privileged \
             --security-opt seccomp=unconfined \
             --tmpfs /tmp \
             --tmpfs /run \
             --volume /var \
             --volume /lib/modules:/lib/modules:ro \
             --network ${mgmt_cluster_name} \
             byoh/node:e2e
done

APISERVER=$(kubectl config view -o jsonpath="{.clusters[?(@.name=='$mgmt_cluster_name')].cluster.server}")
CA_CERT=$(kubectl config view --flatten -o jsonpath="{.clusters[?(@.name=='$mgmt_cluster_name')].cluster.certificate-authority-data}")
echo "APISERVER is $APISERVER in kubeconfig"

cat <<EOF | kubectl apply -f -
apiVersion: infrastructure.cluster.x-k8s.io/v1beta1
kind: BootstrapKubeconfig
metadata:
  name: bootstrap-kubeconfig
  namespace: default
spec:
  apiserver: "$APISERVER"
  certificate-authority-data: "$CA_CERT"
EOF

sleep 2

kubectl get bootstrapkubeconfig bootstrap-kubeconfig -n default -o=jsonpath='{.status.bootstrapKubeconfigData}' > ./bootstrap-kubeconfig.conf
export K3S_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' ${mgmt_cluster_name}-server-0)
echo "K3S API docker IP is $K3S_IP"
sed -i 's/    server\:.*/    server\: https\:\/\/'"$K3S_IP"'\:6443/g' ./bootstrap-kubeconfig.conf

if [[ ! -f byoh-hostagent-linux-amd64 ]]
then
  echo "downloading BYOH binary"
  wget https://github.com/vmware-tanzu/cluster-api-provider-bringyourownhost/releases/download/v0.5.0/byoh-hostagent-linux-amd64
else
  echo "BYOH binary already downloaded"
fi

for i in {1..2}
do
  echo "Copy agent binary to host $i"
  docker cp byoh-hostagent-linux-amd64 host$i:/byoh-hostagent
  echo "Copy kubeconfig to host $i"
  docker cp ./bootstrap-kubeconfig.conf host$i:/bootstrap-kubeconfig.conf
done

# mkdir -p ~/.cluster-api
# cp ${DIR}/clusterAPI/ipam-provider.yaml ~/.cluster-api/clusterctl.yaml

# export PROXMOX_URL="https://proxmox-big.fredcorp.com:8006"
# export PROXMOX_TOKEN='root@pam!clusterapi'
# export PROXMOX_SECRET="$1"

# clusterctl init --infrastructure proxmox --ipam in-cluster

# export PROXMOX_URL="https://proxmox-big.fredcorp.com:8006/api2/json"
# export PROXMOX_USERNAME='root@pam!clusterapi'
# export PROXMOX_TOKEN="$1"
# export PROXMOX_NODE="proxmox-big"
# export PROXMOX_ISO_POOL="local"
# export PROXMOX_BRIDGE="vmbr0"
# export PROXMOX_STORAGE_POOL="local-lvm"
# export DEBUG=1
# export FOREGROUND=1
# export ON_ERROR_ASK=1

# git clone git@github.com:kubernetes-sigs/image-builder.git

# cd image-builder/images/capi

# PACKER_VAR_FILES="${DIR}/clusterAPI/proxmox-bootimg-vars.json" make deps-proxmox
# PACKER_VAR_FILES="${DIR}/clusterAPI/proxmox-bootimg-vars.json" make validate-proxmox-ubuntu-2204
# PACKER_VAR_FILES="${DIR}/clusterAPI/proxmox-bootimg-vars.json" make build-proxmox-ubuntu-2204

# make build-proxmox-ubuntu-2204
