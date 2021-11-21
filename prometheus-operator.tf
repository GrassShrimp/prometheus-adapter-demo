resource "helm_release" "prometheus-operator" {
  name              = "prometheus-operator"
  repository        = "https://prometheus-community.github.io/helm-charts" 
  chart             = "kube-prometheus-stack"
  version           = var.PROMETHEUS_STACK_VERSION
  namespace         = "kube-mon"
  create_namespace  = true
  values = [
  <<EOF
  kubeProxy:
    enabled: false
  kubeControllerManager:
    enabled: false
  kubeEtcd:
    enabled: false
  kubeScheduler:
    enabled: false
  prometheus:
    prometheusSpec:
      replicas: 1
      additionalScrapeConfigs:
      - job_name: 'istiod'
        kubernetes_sd_configs:
        - role: endpoints
          namespaces:
            names:
            - istio-system
        relabel_configs:
        - source_labels: [__meta_kubernetes_service_name, __meta_kubernetes_endpoint_port_name]
          action: keep
          regex: istiod;http-monitoring
      - job_name: 'envoy-stats'
        metrics_path: /stats/prometheus
        kubernetes_sd_configs:
        - role: pod
        relabel_configs:
        - source_labels: [__meta_kubernetes_pod_container_port_name]
          action: keep
          regex: '.*-envoy-prom'
      externalLabels:
        cluster: local
      storageSpec:
        volumeClaimTemplate:
          spec:
            storageClassName: ${module.kind-istio-metallb.storage_class}
            resources:
              requests:
                storage: 1Gi
  alertmanager:
    enabled: false
  grafana:
    enabled: false
  EOF
  ]
  depends_on = [
    module.kind-istio-metallb
  ]
}
resource "local_file" "prometheus_route" {
  content  = <<-EOF
  apiVersion: networking.istio.io/v1beta1
  kind: Gateway
  metadata:
    name: prometheus
  spec:
    selector:
      istio: ingressgateway
    servers:
    - port:
        number: 80
        name: http
        protocol: HTTP
      hosts:
      - prometheus.${module.kind-istio-metallb.ingress_ip_address}.nip.io
  ---
  apiVersion: networking.istio.io/v1beta1
  kind: VirtualService
  metadata:
    name: prometheus
  spec:
    hosts:
    - prometheus.${module.kind-istio-metallb.ingress_ip_address}.nip.io
    gateways:
    - prometheus
    http:
    - route:
      - destination:
          host: prometheus-operator-kube-p-prometheus.${helm_release.prometheus-operator.namespace}.svc.cluster.local
          port:
            number: 9090
  EOF
  filename = "${path.root}/configs/prometheus_route.yaml"
  provisioner "local-exec" {
    command = "kubectl --context ${module.kind-istio-metallb.config_context} apply -f ${self.filename} --namespace ${helm_release.prometheus-operator.namespace}"
  }
}