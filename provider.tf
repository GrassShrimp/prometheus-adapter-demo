terraform {
  required_providers {
    external = {
      source  = "hashicorp/external"
      version = "2.1.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "3.1.0"
    }
    random = {
      source = "hashicorp/random"
      version = "3.1.0"
    }
    local = {
      source = "hashicorp/local"
      version = "2.1.0"
    }
  }
}
provider "kubernetes" {
  config_context = module.kind-istio-metallb.config_context
  config_path    = "~/.kube/config"
}
provider "helm" {
  kubernetes {
    config_context = module.kind-istio-metallb.config_context
    config_path    = "~/.kube/config"
  }
}