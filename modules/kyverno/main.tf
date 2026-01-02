resource "helm_release" "kyverno" {
  name       = "kyverno"
  repository = "https://kyverno.github.io/kyverno/"
  chart      = "kyverno"
  namespace  = "kyverno"
  create_namespace = true
  version    = "3.2.6"
}

resource "helm_release" "kyverno_policies" {
  name       = "kyverno-policies"
  repository = "https://kyverno.github.io/kyverno/"
  chart      = "kyverno-policies"
  namespace  = "kyverno"
  version    = "3.2.6"
  depends_on = [helm_release.kyverno]
}
