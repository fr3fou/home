apiVersion: v1alpha1
kind: LinkConfig
name: eth0
addresses:
  - address: {{ .Node.IP }}/{{ .Data.prefixLength }}
routes:
  - gateway: {{ .Data.gateway }}
    metric: 1024
