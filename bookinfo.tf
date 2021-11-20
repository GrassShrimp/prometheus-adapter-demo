resource "kubernetes_namespace" "bookinfo" {
  metadata {
    name = "bookinfo"
    labels = {
      "istio-injection" = "enabled"
    }
  }
}
resource "null_resource" "bookinfo" {
  triggers = {
    context   = module.kind-istio-metallb.config_context
    namespace = kubernetes_namespace.bookinfo.metadata[0].name
  }
  provisioner "local-exec" {
    command = "kubectl --context ${self.triggers.context} apply -f https://raw.githubusercontent.com/istio/istio/release-1.11/samples/bookinfo/platform/kube/bookinfo.yaml --namespace ${self.triggers.namespace}"
  }
  provisioner "local-exec" {
    when    = destroy
    command = "kubectl --context ${self.triggers.context} delete -f https://raw.githubusercontent.com/istio/istio/release-1.11/samples/bookinfo/platform/kube/bookinfo.yaml --namespace ${self.triggers.namespace}"
  }
  depends_on = [
    module.kind-istio-metallb
  ]
}
resource "local_file" "bookinfo_route" {
  content  = <<-EOF
  apiVersion: networking.istio.io/v1beta1
  kind: Gateway
  metadata:
    name: bookinfo-gateway
  spec:
    selector:
      istio: ingressgateway
    servers:
    - port:
        number: 80
        name: http
        protocol: HTTP
      hosts:
      - bookinfo.${module.kind-istio-metallb.ingress_ip_address}.nip.io
  ---
  apiVersion: networking.istio.io/v1beta1
  kind: VirtualService
  metadata:
    name: bookinfo-virtualservice
  spec:
    hosts:
    - bookinfo.${module.kind-istio-metallb.ingress_ip_address}.nip.io
    gateways:
    - bookinfo-gateway
    http:
    - match:
      - uri:
          prefix: "/"
      route:
      - destination:
          host: productpage.bookinfo.svc.cluster.local
          port:
            number: 9080
  EOF
  filename = "${path.root}/configs/bookinfo_route.yaml"
  provisioner "local-exec" {
    command = "kubectl --context ${module.kind-istio-metallb.config_context} apply -f ${self.filename} --namespace ${kubernetes_namespace.bookinfo.metadata[0].name}"
  }
  depends_on = [
    module.kind-istio-metallb,
    null_resource.bookinfo
  ]
}
resource "kubernetes_horizontal_pod_autoscaler" "productpage-v1" {
  metadata {
    name      = "productpage-v1"
    namespace = kubernetes_namespace.bookinfo.metadata[0].name
  }

  spec {
    scale_target_ref {
      kind        = "Deployment"
      name        = "productpage-v1"
      api_version = "apps/v1"
    }

    min_replicas = 1
    max_replicas = 10

    metric {
      type = "Object"
      object {
        described_object {
          api_version = "apps/v1"
          kind        = "Deployment"
          name        = "productpage-v1"
        }
        metric {
          name = "istio_request_duration_milliseconds_bucket"
        }
        target {
          type          = "AverageValue"
          average_value = 100
        }
      }
    }

    behavior {
      scale_down {
        select_policy                = "Max"
        stabilization_window_seconds = 60

        policy {
          period_seconds = 15
          type           = "Percent"
          value          = 100
        }
      }
      scale_up {
        select_policy                = "Max"
        stabilization_window_seconds = 0

        policy {
          period_seconds = 15
          type           = "Pods"
          value          = 4
        }
        policy {
          period_seconds = 15
          type           = "Percent"
          value          = 100
        }
      }
    }
  }
  depends_on = [
    null_resource.bookinfo
  ]
}
