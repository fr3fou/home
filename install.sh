#!/usr/bin/env sh

IP=$(hostname -I | awk '{print $1}')

curl -sfL https://get.k3s.io | \
	INSTALL_K3S_EXEC="--disable helm-controller \
		--disable traefik \
		--disable servicelb \
		--bind-address ${IP} \
		--node-ip ${IP} \
		--advertise-address ${IP} \
		--node-external-ip ${IP}" \
	sh -  >/dev/null

until [ -f /etc/rancher/k3s/k3s.yaml ]
do
	sleep 1
done

sudo cat /etc/rancher/k3s/k3s.yaml
