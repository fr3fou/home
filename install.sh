#!/usr/bin/env sh
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--disable helm-controller --disable traefik" sh -
echo "Finished installing k3s..."
echo "kubeconfig:"
sudo cat /etc/rancher/k3s/k3s.yaml
