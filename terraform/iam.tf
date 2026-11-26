# ========================================================
# Создаем SA и назначаем роли для k8s
# ========================================================

resource "yandex_iam_service_account" "k8s_cluster_sa" {
  name        = "k8s-cluster-sa"
  description = "SA для control plane и управления ресурсами кластера"
}

resource "yandex_iam_service_account" "k8s_node_sa" {
  name        = "k8s-node-sa"
  description = "SA для узлов"
}

resource "yandex_resourcemanager_folder_iam_member" "cluster_agent" {
  folder_id = var.yc_folder_id
  role      = "k8s.clusters.agent"
  member    = "serviceAccount:${yandex_iam_service_account.k8s_cluster_sa.id}"
}

resource "yandex_resourcemanager_folder_iam_member" "cluster_vpc_public" {
  folder_id = var.yc_folder_id
  role      = "vpc.publicAdmin"
  member    = "serviceAccount:${yandex_iam_service_account.k8s_cluster_sa.id}"
}

# ========================================================
# SA и статический ключ для доступа приложения к S3
# ========================================================

resource "yandex_iam_service_account" "s3_app_sa" {
  name        = "s3-app-sa"
  description = "SA для доступа приложения к S3"
}

resource "yandex_resourcemanager_folder_iam_member" "s3_app_sa_storage" {
  folder_id = var.yc_folder_id
  role      = "storage.editor"
  member    = "serviceAccount:${yandex_iam_service_account.s3_app_sa.id}"
}

resource "yandex_iam_service_account_static_access_key" "s3_app_key" {
  service_account_id = yandex_iam_service_account.s3_app_sa.id
  description        = "static access key для доступа приложения к S3"
  depends_on         = [yandex_resourcemanager_folder_iam_member.s3_app_sa_storage]
}