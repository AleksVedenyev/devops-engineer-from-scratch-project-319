# ========================================================
# Lockbox: чувствительные параметры приложения
# ========================================================

resource "yandex_lockbox_secret" "app_secret" {
  name      = "app-secret"
  folder_id = var.yc_folder_id
}


resource "yandex_lockbox_secret_version_hashed" "app_secret_v1" {
  secret_id = yandex_lockbox_secret.app_secret.id

  key_1        = "SPRING_DATASOURCE_URL"
  text_value_1 = local.postgres_connection_string

  key_2        = "SPRING_DATASOURCE_USERNAME"
  text_value_2 = yandex_mdb_postgresql_user.app.name

  key_3        = "SPRING_DATASOURCE_PASSWORD"
  text_value_3 = yandex_mdb_postgresql_user.app.password

  key_4        = "STORAGE_S3_ACCESSKEY"
  text_value_4 = yandex_storage_bucket.app_bucket.access_key

  key_5        = "STORAGE_S3_SECRETKEY"
  text_value_5 = yandex_storage_bucket.app_bucket.secret_key
}
