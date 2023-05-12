resource "kubernetes_namespace" "pipeline-namespace" {
  metadata {
    name = "${var.namespace}"
  }
}

resource "kubernetes_secret" "credentials" {
    metadata {
      name = "credentials"
      namespace = "${var.namespace}"
    }

    depends_on = [ kubernetes_namespace.pipeline-namespace ]

    data = {
      "credentials.cfg" = "${file("../secrets/credentials.cfg")}"
    }
}