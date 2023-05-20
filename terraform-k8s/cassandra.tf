resource "kubernetes_deployment" "cassandra" {
  metadata {
    name = "cassandra"
    namespace = "${var.namespace}"
    labels = {
      "k8s.service" = "cassandra"
    }
  }

  depends_on = [
        kubernetes_persistent_volume_claim.cassandravolume,
        kubernetes_persistent_volume.cassandravolume
  ]

  spec {
    replicas = 1

    selector {
      match_labels = {
        "k8s.service" = "cassandra"
      }
    }

    template {
      metadata {
        labels = {
          "k8s.network/pipeline-network" = "true"

          "k8s.service" = "cassandra"
        }
      }

      spec {
        hostname = "cassandra"
        restart_policy = "Always"
        volume {
          name = "cassandra-data"

          persistent_volume_claim {
            claim_name = "cassandravolume"
          }
        }

        container {
          name  = "cassandra"
          image = "nama1arpit/cassandra:latest"

          port {
            container_port = 9042
          }

          env {
            name  = "CASSANDRA_CLUSTER_NAME"
            value = "CassandraCluster"
          }

          env {
            name  = "CASSANDRA_DATACENTER"
            value = "DataCenter1"
          }

          env {
            name  = "CASSANDRA_ENDPOINT_SNITCH"
            value = "GossipingPropertyFileSnitch"
          }

          env {
            name  = "CASSANDRA_HOST"
            value = "cassandra"
          }

          env {
            name  = "CASSANDRA_NUM_TOKENS"
            value = "128"
          }

          env {
            name  = "CASSANDRA_RACK"
            value = "Rack1"
          }

          env {
            name  = "HEAP_NEWSIZE"
            value = "128M"
          }

          env {
            name  = "MAX_HEAP_SIZE"
            value = "256M"
          }

          env {
            name = "POD_IP"

            value_from {
              field_ref {
                field_path = "status.podIP"
              }
            }
          }

          volume_mount {
            name       = "cassandra-data"
            mount_path = "/var/lib/cassandra"
          }
        }

        container {
          name  = "cassandrainit"
          image = "nama1arpit/cassandra:latest"

          command = [
            "/bin/sh",
            "-c",
            "echo waiting 30 sec for cassandra to start && sleep 30 && echo loading cassandra keyspace && cqlsh cassandra -f /cassandra-setup.cql && echo finished setting up cassandra tables && tail -f /dev/null"
          ]
        }
      }
    }
  }
}

resource "kubernetes_service" "cassandra" {
  metadata {
    name = "cassandra"
    namespace = "${var.namespace}"
    labels = {
      "k8s.service" = "cassandra"
    }
  }

  depends_on = [ kubernetes_deployment.cassandra ]

  spec {
    port {
      name        = "9042"
      port        = 9042
      target_port = 9042
    }

    selector = {
      "k8s.service" = "cassandra"
    }

    cluster_ip = "None"
  }
}
