#!/bin/bash

DIR=$(pwd)/post-install/:/var/lib/rancher/k3s/server/manifests/

yq eval -i '.volumes[].volume = "'"$DIR"'"' k3s.yaml

k3d cluster delete --config k3s.yaml
k3d cluster create --config k3s.yaml