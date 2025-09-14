#!/usr/bin/env bash

if [ -z $GITHUB_TOKEN ]; then
  echo "GITHUB_TOKEN is not defined"
  exit 1
fi

kubectl create namespace flux-system

cat "$HOME/Library/Application Support/sops/age/keys.txt" | kubectl create secret generic sops-age --namespace=flux-system --from-file=sops.agekey=/dev/stdin

flux bootstrap github \
  --owner=fr3fou \
  --repository=home \
  --path=nerv/main/flux \
  --personal
