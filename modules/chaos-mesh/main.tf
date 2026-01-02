resource "helm_release" "chaos_mesh" {
  name       = "chaos-mesh"
  repository = "https://charts.chaos-mesh.org"
  chart      = "chaos-mesh"
  namespace  = "chaos-mesh"
  create_namespace = true
  version    = "2.6.3"

  set {
    name  = "chaosDaemon.runtime"
    value = "containerd"
  }

  set {
    name  = "chaosDaemon.socketPath"
    value = "/run/containerd/containerd.sock"
  }
}
