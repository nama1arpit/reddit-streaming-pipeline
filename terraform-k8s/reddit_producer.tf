resource "kubernetes_deployment" "redditproducer" {
  metadata {
    name = "redditproducer"
    namespace = "${var.namespace}"
    labels = {
        "k8s.service" = "redditproducer"
    }
  }

  # should start after kafka topic creation
  depends_on = [ kubernetes_deployment.kafkaservice, kubernetes_deployment.cassandra ]

  spec {
    replicas = 1

    selector {
      match_labels = {
        "k8s.service" = "redditproducer"
      }
    }

    template {
      metadata {
        labels = {
          "k8s.service" = "redditproducer"

          "k8s.network/pipeline-network" = "true"
        }
      }

      spec {
        container {
          name = "redditproducer"
          image = "nama1arpit/reddit_producer:latest"

          volume_mount {
            name = "credentials"
            mount_path = "/app/secrets/"
            read_only = true
          }
        }

        volume {
          name = "credentials"

          secret {
            secret_name = kubernetes_secret.credentials.metadata[0].name
          }
        }
        restart_policy = "Always"
      }
    }
  }
}

resource "kubernetes_service" "redditproducer" {
  metadata {
    name = "redditproducer"
    namespace = "${var.namespace}"
    labels = {
      "k8s.service" = "redditproducer"
    }
  }


  depends_on = [ kubernetes_deployment.redditproducer ]

  spec {
    selector = {
        "k8s.service" = "redditproducer"
    }

    cluster_ip = "None"
  }
}