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

#! may not need it
resource "kubernetes_network_policy" "pipeline_network" {
  metadata {
    name = "pipeline-network"
    namespace = "${var.namespace}"
  }

  depends_on = [ kubernetes_namespace.pipeline-namespace ]

  spec {
    pod_selector {
      match_labels = {
        "k8s.network/pipeline-network" = "true"
      }
    }

    policy_types = ["Ingress"]

    ingress {
      from {
        pod_selector {
          match_labels = {
            "k8s.network/pipeline-networ" = "true"
          }
        }
      }
    }
  }
}