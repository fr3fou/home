# home

## Bootstrap

Cluster is configured using [k3sup](https://github.com/alexellis/k3sup)

```sh
$ k3sup install \
    --merge \
    --context $CONTEXT \
    --ip $IP \
    --user $USER \
    --ssh-key ~/.ssh/id_ed25519 \ # Use this if you don't use RSA keys
    --local-path $HOME/.kube/config
```
