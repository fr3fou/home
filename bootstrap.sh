#!/usr/bin/env bash

kubectl create namespace flux-system

export SOPS_AGE_KEY_FILE=$(cat .sops.yaml | yq -r '.creation_rules[0].age')

cat age.agekey |
	kubectl create secret generic sops-age \
	--namespace=flux-system \
	--from-file=sops.agekey=/dev/stdin

flux bootstrap github \
  --owner=fr3fou \
  --repository=home \
  --path=clusters/anton \
  --personal
