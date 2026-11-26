# ========================================================
# Создаем кластер PostgreSQL
# ========================================================

resource "yandex_mdb_postgresql_cluster" "pg_cluster" {
  name                = "pg-cluster"
  environment         = "PRODUCTION"
  network_id          = yandex_vpc_network.k8s_network.id
  security_group_ids  = [yandex_vpc_security_group.pg_sg.id]
  deletion_protection = false

  config {
    version = "17"
    resources {
      resource_preset_id = "s2.micro"
      disk_type_id       = "network-ssd"
      disk_size          = "10"
    }
  }

  host {
    zone             = "ru-central1-a"
    name             = "pg-host-a"
    subnet_id        = yandex_vpc_subnet.pg_subnet.id
    assign_public_ip = false
  }
}

resource "random_password" "db" {
  length  = 16
  special = false
}

resource "yandex_mdb_postgresql_database" "app_db" {
  cluster_id = yandex_mdb_postgresql_cluster.pg_cluster.id
  name       = "app-db"
  owner      = "app"
  depends_on = [
    yandex_mdb_postgresql_user.app
  ]
}

resource "yandex_mdb_postgresql_user" "app" {
  cluster_id = yandex_mdb_postgresql_cluster.pg_cluster.id
  name       = "app"
  password   = random_password.db.result
}