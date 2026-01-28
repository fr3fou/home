# nerv Cluster - Agent Documentation

This document describes the structure and conventions used in the nerv Kubernetes cluster for AI agents and contributors.

## Overview

nerv is a GitOps-managed Kubernetes cluster using:
- **Flux CD** for continuous deployment
- **SOPS + AGE** for secret encryption
- **CloudNativePG** for PostgreSQL databases
- **Envoy Gateway** for ingress (Gateway API)
- **bjw-s app-template** Helm chart for most applications

## Directory Structure

```
nerv/main/cluster/
├── apps/                          # Application deployments
│   ├── kustomization.yaml         # Root - lists all apps
│   ├── namespace.yaml             # apps namespace
│   ├── app-template.yaml          # Shared OCI repository for bjw-s helm chart
│   ├── shared/
│   │   ├── postgres/              # CloudNativePG shared cluster
│   │   └── redis/                 # Shared Redis
│   └── <app-name>/
│       ├── ks.yaml                # Flux Kustomization (entry point)
│       └── app/
│           ├── kustomization.yaml
│           ├── helmrelease.yaml
│           └── secret.yaml        # SOPS-encrypted
├── networking-system/
│   └── envoy-gateway/             # Gateway configuration
└── ...
```

## Adding a New Application

### 1. Create App Directory

```bash
mkdir -p nerv/main/cluster/apps/<app-name>/app
```

### 2. Create Flux Kustomization (ks.yaml)

```yaml
---
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: &app <app-name>
  namespace: flux-system
spec:
  targetNamespace: apps
  path: ./nerv/main/cluster/apps/<app-name>/app
  prune: true
  sourceRef:
    kind: GitRepository
    name: flux-system
  wait: false
  interval: 30m
  retryInterval: 1m
  timeout: 5m
  dependsOn:
    - name: shared-postgres  # If app needs database
```

### 3. Create HelmRelease

Uses bjw-s app-template. Key sections:

```yaml
---
apiVersion: helm.toolkit.fluxcd.io/v2
kind: HelmRelease
metadata:
  name: <app-name>
  namespace: apps
spec:
  interval: 15m
  chartRef:
    kind: OCIRepository
    name: app-template
    namespace: apps
  values:
    controllers:
      <app-name>:
        pod:
          securityContext:
            runAsUser: 1000
            runAsGroup: 1000
            runAsNonRoot: true
            fsGroup: 1000
            fsGroupChangePolicy: OnRootMismatch
        containers:
          app:
            image:
              repository: <image>
              tag: <tag>@sha256:<digest>
            env:
              # Direct env vars
            envFrom:
              - secretRef:
                  name: <app-name>
            probes:
              liveness: &probes
                enabled: true
                custom: true
                spec:
                  httpGet:
                    path: /health
                    port: &port 8080
              readiness: *probes
            securityContext:
              allowPrivilegeEscalation: false
              readOnlyRootFilesystem: true
              capabilities:
                drop: ["ALL"]

    service:
      app:
        controller: <app-name>
        ports:
          http:
            port: *port

    route:
      app:
        hostnames:
          - <app>.nerv.id
        parentRefs:
          - name: internal  # or external
            namespace: networking-system
        rules:
          - backendRefs:
              - name: <app-name>
                port: *port

    persistence:
      data:
        type: persistentVolumeClaim
        accessMode: ReadWriteOnce
        size: 1Gi
        storageClass: local-path
        globalMounts:
          - path: /data
```

### 4. Create App Kustomization

```yaml
---
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - ./helmrelease.yaml
  - ./secret.yaml
```

### 5. Create and Encrypt Secrets

Create plaintext secret:
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: <app-name>
  namespace: apps
type: Opaque
stringData:
  KEY: value
```

Encrypt with SOPS:
```bash
sops --encrypt --in-place nerv/main/cluster/apps/<app-name>/app/secret.yaml
```

### 6. Register App

Add to `nerv/main/cluster/apps/kustomization.yaml`:
```yaml
resources:
  - <app-name>/ks.yaml
```

## Adding PostgreSQL Database for an App

### 1. Create User Secret

Create `nerv/main/cluster/apps/shared/postgres/app/postgres-<app>-user-secret.yaml`:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: postgres-<app>-user
  namespace: apps
type: Opaque
stringData:
  username: <app_name>  # Use underscores for PG identifiers
  password: <generate-strong-password>
```

Encrypt it:
```bash
sops --encrypt --in-place nerv/main/cluster/apps/shared/postgres/app/postgres-<app>-user-secret.yaml
```

### 2. Add Role to Cluster

Edit `nerv/main/cluster/apps/shared/postgres/app/postgres-cluster.yaml`:

```yaml
managed:
  roles:
    # ... existing roles ...
    - name: <app_name>
      ensure: present
      login: true
      superuser: false
      passwordSecret:
        name: postgres-<app>-user
```

### 3. Add Database

Edit `nerv/main/cluster/apps/shared/postgres/app/databases.yaml`:

```yaml
---
apiVersion: postgresql.cnpg.io/v1
kind: Database
metadata:
  name: <app>
  namespace: apps
spec:
  cluster:
    name: postgres-apps
  name: <app_name>
  owner: <app_name>
```

### 4. Update Shared Postgres Kustomization

Edit `nerv/main/cluster/apps/shared/postgres/app/kustomization.yaml`:

```yaml
resources:
  # ... existing secrets ...
  - postgres-<app>-user-secret.yaml
  - postgres-cluster.yaml
  - databases.yaml
```

### 5. Database Connection String

In your app's secret, use:
```
postgres://<app_name>:<password>@postgres-apps-rw.apps.svc.cluster.local:5432/<app_name>
```

## Secrets Management

### SOPS Configuration

Located at `nerv/.sops.yaml`:
```yaml
creation_rules:
  - encrypted_regex: '((?i)(pass($|word)|claim|secret($|[^N])|key|token|^data$|^stringData|^databaseUrl))'
    age: age194r4u78jlkcg3waxh5ddpwe6y0pwenuhk9avnkmc3huzcpf26d0spa3ggf
```

### Commands

```bash
# Encrypt a file
sops --encrypt --in-place <file.yaml>

# Decrypt for viewing
sops --decrypt <file.yaml>

# Edit in-place
sops <file.yaml>
```

## Networking

### Gateways

| Gateway | IP | Use Case |
|---------|-----|----------|
| `internal` | 192.168.5.12 | Internal services (*.nerv.id) |
| `external` | 192.168.5.11 | Public-facing services |

### HTTPRoute Example

```yaml
route:
  app:
    hostnames:
      - app.nerv.id
    parentRefs:
      - name: internal  # or external
        namespace: networking-system
    rules:
      - backendRefs:
          - name: <service-name>
            port: 8080
```

## Reference Repositories

The `.ref/` directory (gitignored) contains reference homelab repos.

## Conventions

1. **Namespaces**: Most apps go in `apps` namespace
2. **Image tags**: Always pin with SHA digest (`tag@sha256:...`)
3. **Security contexts**: Always set `runAsNonRoot`, `readOnlyRootFilesystem`, drop capabilities
4. **Probes**: Always configure liveness and readiness probes
5. **Resources**: Always set requests and limits
6. **Secrets**: Never commit plaintext secrets - always SOPS encrypt
7. **PG identifiers**: Use underscores (`pocket_id`) not hyphens
