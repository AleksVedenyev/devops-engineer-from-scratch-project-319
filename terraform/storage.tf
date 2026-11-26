# ========================================================
# Object Storage bucket для приложения
# ========================================================

resource "yandex_storage_bucket" "app_bucket" {
  bucket                = "app-bucket-project-devops-deploy"
  folder_id             = var.yc_folder_id
  max_size              = 30000000
  default_storage_class = "STANDARD"

  access_key = yandex_iam_service_account_static_access_key.s3_app_key.access_key
  secret_key = yandex_iam_service_account_static_access_key.s3_app_key.secret_key

  anonymous_access_flags {
    read = false
    list = false
  }

}