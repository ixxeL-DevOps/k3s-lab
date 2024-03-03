#!/usr/bin/env bash

DIR=$(pwd)/post-install/:/var/lib/rancher/k3s/server/manifests/

yq eval -i '.volumes[].volume = "'"$DIR"'"' k3s.yaml

k3d cluster delete --config k3s.yaml
k3d cluster create --wait --config k3s.yaml

sed -i 's/forward \. \/etc\/resolv\.conf/forward \. 192.168.1.200/' post-install/coredns.yaml