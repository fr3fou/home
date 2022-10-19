# home

```sh
$ # Run this on the master nodes
$ curl -sfL https://raw.githubusercontent.com/fr3fou/home/main/install.sh | sh -
```

## TODO

- [x] Proper dependency management with FluxCD's `dependsOn`
- [x] `external-dns` for automatic DNS records
- [ ] `metallb` instead of klipper-lb as it isn't [web scale](https://www.youtube.com/watch?v=b2F-DItXtZs) - there are some issues with using klipper-lb due to the way its designed, most notably https://github.com/k3s-io/klipper-lb/issues/27 & https://github.com/k3s-io/klipper-lb/issues/31
- [ ] Implement some ideas from [onedr0p/home-ops](https://github.com/onedr0p/home-ops#-dns) - use an internal DNS for internal services, but keep using external-dns for external services
- [x] [kube-prometheus-stack](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack)
- [x] [freshrss](https://github.com/FreshRSS/FreshRSS)
- [x] [reddit-rss](https://github.com/trashhalo/reddit-rss) 
- [x] [libreddit](https://github.com/spikecodes/libreddit)
- [ ] [recyclarr](https://github.com/recyclarr/recyclarr)
- [ ] [bazarr](https://github.com/morpheus65535/bazarr)
- [ ] [renovate](https://github.com/renovatebot/renovate)
- [ ] Backups for PVs
- [ ] Group applications by namespaces - e.g `monitoring`, `rss`, `media-server`, `downloads`, etc
