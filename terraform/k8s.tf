# ========================================================
# Создаем кластер k8s
# ========================================================

resource "yandex_kubernetes_cluster" "k8s_cluster" {
  name                    = "k8s-cluster"
  service_account_id      = yandex_iam_service_account.k8s_cluster_sa.id
  node_service_account_id = yandex_iam_service_account.k8s_node_sa.id
  depends_on = [
    yandex_resourcemanager_folder_iam_member.cluster_agent,
    yandex_resourcemanager_folder_iam_member.cluster_vpc_public,
  ]
  cluster_ipv4_ranges = [local.k8s_pod_cidr]
  service_ipv4_range  = local.k8s_service_cidr
  network_id          = yandex_vpc_network.k8s_network.id
  master {
    master_location {
      zone      = "ru-central1-a"
      subnet_id = yandex_vpc_subnet.k8s_subnet_master.id
    }
    security_group_ids = [
      yandex_vpc_security_group.k8s-cluster-nodegroup-traffic.id,
      yandex_vpc_security_group.k8s-cluster-traffic.id
    ]

    public_ip = true
  }
}

resource "yandex_kubernetes_node_group" "worker_node" {
  cluster_id = yandex_kubernetes_cluster.k8s_cluster.id
  name       = "worker-node"
  allocation_policy {
    location {
      zone = "ru-central1-a"
    }
  }
  scale_policy {
    fixed_scale {
      size = 1
    }
  }
  instance_template {
    platform_id = "standard-v3"

    resources {
      cores         = 2
      core_fraction = 100
      memory        = 4
    }

    boot_disk {
      type = "network-ssd"
      size = 32
    }

    network_interface {
      subnet_ids = [yandex_vpc_subnet.k8s_subnet_node.id]
      security_group_ids = [
        yandex_vpc_security_group.k8s-cluster-nodegroup-traffic.id,
        yandex_vpc_security_group.k8s-nodegroup-traffic.id,
        yandex_vpc_security_group.k8s-services-access.id,
      ]
    }
  }
}