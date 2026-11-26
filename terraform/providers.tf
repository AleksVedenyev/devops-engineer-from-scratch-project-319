provider "yandex" {
  zone      = "ru-central1-a"
  folder_id = var.yc_folder_id
  cloud_id  = var.yc_cloud_id
}

provider "random" {
}