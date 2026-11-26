terraform {
  required_version = ">= 1.11.0"

  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = "~> 0.132"
    }

    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}