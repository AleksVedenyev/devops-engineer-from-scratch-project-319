output "k8s_cluster_id" {
  value       = yandex_kubernetes_cluster.k8s_cluster.id
  description = "ID кластера"
}

output "k8s_node_group_id" {
  value       = yandex_kubernetes_node_group.worker_node.id
  description = "ID группы узлов"
}

output "cluster_endpoint" {
  value       = yandex_kubernetes_cluster.k8s_cluster.master[0].external_v4_endpoint
  description = "Эндпоинт кластера"
  sensitive   = true
}

output "cluster_ca_certificate" {
  value       = yandex_kubernetes_cluster.k8s_cluster.master[0].cluster_ca_certificate
  description = "CA-сертификат кластера"
  sensitive   = true
}

output "db_connection_string" {
  value       = local.postgres_connection_string
  description = "Строка подключения к БД"
  sensitive   = true
}

output "lockbox_secret_id" {
  value       = yandex_lockbox_secret.app_secret.id
  description = "ID секрета Lockbox с параметрами приложения"
}

output "s3_bucket" {
  value       = yandex_storage_bucket.app_bucket.bucket
  description = "Имя бакета"
}

output "s3_access_key" {
  value       = yandex_storage_bucket.app_bucket.access_key
  description = "S3 access key"
  sensitive   = true
}

output "s3_secret_key" {
  value       = yandex_storage_bucket.app_bucket.secret_key
  description = "S3 secret key"
  sensitive   = true
}