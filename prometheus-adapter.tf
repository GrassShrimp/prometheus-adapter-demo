resource "helm_release" "prometheus-adapter" {
  name              = "prometheus-adapter"
  repository        = "https://prometheus-community.github.io/helm-charts" 
  chart             = "prometheus-adapter"
  version           = var.PROMETHEUS_ADAPTER_VERSION
  namespace         = helm_release.prometheus-operator.namespace
  values = [
    <<EOF
    prometheus:
      url: http://prometheus-operator-kube-p-prometheus.${helm_release.prometheus-operator.namespace}.svc.cluster.local
      port: 9090
    rules:
      default: false
      custom:
      - seriesQuery: '{__name__=~"^istio_request_duration_milliseconds_.*",destination_workload!="",destination_workload_namespace!="",reporter="destination"}'
        resources:
          overrides:
            destination_workload: {group: "apps", resource: "deployment"}
            destination_workload_namespace: {resource: "namespace"}
        name:
          matches: "^istio_request_duration_milliseconds_(.*)$"
          as: "istio_request_duration_milliseconds_$${1}"
        metricsQuery: 'sum(rate(istio_request_duration_milliseconds_sum{<<.LabelMatchers>>,reporter="destination"}[2m])) by (<<.GroupBy>>) / sum(rate(istio_request_duration_milliseconds_count{<<.LabelMatchers>>,reporter="destination"}[2m]) + 1) by (<<.GroupBy>>)'
    EOF
  ]
}
