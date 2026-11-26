locals {
  # Внутренние сети Kubernetes кластера
  k8s_pod_cidr     = "10.96.0.0/16"
  k8s_service_cidr = "10.112.0.0/16"

  # Подсети в VPC
  k8s_subnet_master_cidr = "10.10.0.0/16"
  k8s_subnet_node_cidr   = "10.20.0.0/16"
  pg_subnet_cidr         = "10.30.0.0/16"


  anywhere_cidr = "0.0.0.0/0"

  # Строка подключения к БД
  postgres_connection_string = "jdbc:postgresql://${yandex_mdb_postgresql_cluster.pg_cluster.host[0].fqdn}:6432/${yandex_mdb_postgresql_database.app_db.name}?targetServerType=master&sslmode=require"
}