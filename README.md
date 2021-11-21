# prometheus-adapter-demo

This is a simple demonstration of local cluster auto-scaling through [proemtheus adapter](https://github.com/kubernetes-sigs/prometheus-adapter)
## Prerequisites
- [terraform](https://www.terraform.io/downloads.html)
- [docker](https://www.docker.com/products/docker-desktop) or [podman](https://podman.io/getting-started/installation)
- [kind](https://kind.sigs.k8s.io/docs/user/quick-start#installation)
- [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)
- [helm](https://helm.sh/docs/intro/install/)
- siege - brew install siege or sudo apt install siege -y

## Usage

initialize terraform module

```bash
$ terraform init
```

launch enviroment

```bash
$ terraform apply -auto-approve
```

cleanup enviroment

```bash
$ terraform destroy -auto-approve
```

## Demo Video

[![prometheus-adapter](https://github.com/GrassShrimp/prometheus-adapter-demo/blob/master/prometheus-adapter-demo.png)](https://youtu.be/dkNHbNExsOQ)