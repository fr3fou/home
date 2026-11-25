# home

```sh
$ # Run this on the master nodes
$ curl -sfL https://raw.githubusercontent.com/fr3fou/home/main/install.sh | sh -
```

## Secrets

Make sure you add the secret age key to the corresponding directory.

https://github.com/mozilla/sops#22encrypting-using-age

## Talos

Machine configs for the `nerv` cluster are managed with
[topf](https://github.com/postfinance/topf) from `nerv/talos/`
(`brew install postfinance/tap/topf`).

- `topf.yaml`: cluster, versions and nodes; per-node Image Factory
  schematics live in `schematics/`.
- Patches merge in order `all/` → `control-plane/` → `node/<host>/`.
  Talos ≥ 1.14 rejects configs that set a legacy v1alpha1 field *and* its
  replacement document, so write patches as new-style documents
  (`KubeNodeConfig`, `KubeProxyConfig`, …).
- `secrets.sops.yaml`: SOPS-encrypted Talos secrets bundle, decrypted by topf.

```sh
cd nerv/talos
topf render                        # write configs to ./output (gitignored)
topf apply --dry-run               # server-side diff; exit 2 on changes
topf apply                         # apply (prompts for confirmation)
topf upgrade                       # roll Talos to talosVersion/schematics
(umask 077; topf talosconfig > talosconfig)   # used via .envrc
(umask 077; topf kubeconfig > kubeconfig)     # 12h admin kubeconfig
```

New or changed schematics must be registered once with `--submit-to-factory`.
