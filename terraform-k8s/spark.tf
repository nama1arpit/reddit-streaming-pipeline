resource "kubernetes_deployment" "spark" {
  metadata {
    name = "spark"
    namespace = "${var.namespace}"
    labels = {
      "k8s.service" = "spark"
    }
  }

  depends_on = [ kubernetes_service.redditproducer, kubernetes_service.cassandra ]

  spec {
    replicas = 1

    selector {
      match_labels = {
        "k8s.service" = "spark"
      }
    }

    template {
      metadata {
        labels = {
            "k8s.service" = "spark"

            "k8s.network/pipeline-network" = "true"
        }
      }

      spec {
        container {
          name = "spark"
          image = "nama1arpit/spark_stream_processor:latest"
          image_pull_policy = "Always"

          # environment variables
          env {
            name = "KAFKA_BROKERS"
            value = "kafkaservice.${var.namespace}.svc.cluster.local:9092"
          }

          env {
            name = "KAFKA_TOPIC"
            value = "redditcomments"
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "spark" {
  metadata {
    name = "spark"
    namespace = "${var.namespace}"
    labels = {
        "k8s.service" = "spark"
    }
  }

  depends_on = [ kubernetes_deployment.spark ]

  spec {
    selector = {
        "k8s.service" = "spark"
    }

    cluster_ip = "None"
  }
}