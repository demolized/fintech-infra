################################################################################
# Prometheus WorkSpace
################################################################################

module "prometheus" {
  source = "terraform-aws-modules/managed-service-prometheus/aws"

  workspace_alias  = "eks-workspace"
  create_workspace = true

  alert_manager_definition = <<-EOT
  alertmanager_config: |
    route:
      receiver: 'default'
    receivers:
      - name: 'default'
  EOT

  rule_group_namespaces = {
    slo_rules = {
      name = "slo-rules"
      data = <<-EOT
      groups:
        - name: availability-slo
          rules:
          - alert: LowAvailability
            expr: sum(rate(http_requests_total{status=~"5.."}[5m])) / sum(rate(http_requests_total[5m])) > 0.01
            for: 2m
            labels:
              severity: critical
            annotations:
              summary: "Availability SLO violated"
              description: "Error rate is above 1% for the last 5 minutes."
        - name: latency-slo
          rules:
          - alert: HighLatency
            expr: histogram_quantile(0.95, sum(rate(http_request_duration_seconds_bucket[5m])) by (le)) > 0.5
            for: 5m
            labels:
              severity: warning
            annotations:
              summary: "Latency SLO violated"
              description: "95th percentile latency is above 500ms."
      EOT
    }
  }
}

################################################################################
# Prometheus Namespace
################################################################################

resource "kubernetes_namespace" "prometheus-namespace" {
  metadata {
    annotations = {
      name = "monitoring"
    }

    labels = {
      application = "monitoring"
    }

    name = "monitoring"
  }
}

################################################################################
# Prometheus Role
################################################################################

module "prometheus_role" {
  source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"

  role_name                                        = "${var.env_name}_prometheus"
  attach_amazon_managed_service_prometheus_policy  = true
  amazon_managed_service_prometheus_workspace_arns = [module.prometheus.workspace_arn]

  oidc_providers = {
    main = {
      provider_arn               = var.oidc_provider_arn
      namespace_service_accounts = ["${kubernetes_namespace.prometheus-namespace.metadata[0].name}:amp-iamproxy-ingest-role"]
    }
  }

}

################################################################################
# Prometheus Service Account
################################################################################

resource "kubernetes_service_account" "service-account" {
  metadata {
    name      = "amp-iamproxy-ingest-role"
    namespace = kubernetes_namespace.prometheus-namespace.metadata[0].name
    labels = {
      "app.kubernetes.io/name" = "prometheus"
    }
    annotations = {
      "eks.amazonaws.com/role-arn"               = module.prometheus_role.iam_role_arn
      "eks.amazonaws.com/sts-regional-endpoints" = "true"
    }
  }
}


################################################################################
# Install Prometheus With Helm
################################################################################

resource "helm_release" "prometheus" {
  name       = "prometheus-community"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "prometheus"
  version    = "23.1.0"
  namespace  = kubernetes_namespace.prometheus-namespace.metadata[0].name
  depends_on = [
    kubernetes_service_account.service-account
  ]

  values = [
    "${file("${path.module}/templates/amp_ingest_override_values.yaml")}"
  ]

  set {
    name  = "server.remoteWrite[0].url"
    value = "${module.prometheus.workspace_prometheus_endpoint}api/v1/remote_write"
  }

  set {
    name  = "server.remoteWrite[0].sigv4.region"
    value = var.main-region
  }

}

