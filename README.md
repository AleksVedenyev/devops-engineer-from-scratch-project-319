# Доска объявлений(Kubernetes)

[![hexlet-check](https://github.com/AleksVedenyev/devops-engineer-from-scratch-project-319/actions/workflows/hexlet-check.yml/badge.svg)](https://github.com/AleksVedenyev/devops-engineer-from-scratch-project-319/actions)

Разверните приложение в Managed Kubernetes в облаке. Кластер описывается в Terraform, приложение выкатывается Helm-чартом, а метрики, логи и секреты подключаются к кластеру.

## Инфраструктура проекта в Yandex Cloud (Terraform)

Terraform-конфигурация для приложения. Создаёт:

- **VPC**: сеть, три подсети (мастер, ноды, PostgreSQL), NAT-шлюз, таблицу маршрутизации и security group;
- **Managed Kubernetes**: кластер и группу из одной worker-ноды, сервисные аккаунты для кластера и нод;
- **Managed PostgreSQL**: кластер из одного хоста без публичного IP, база и пользователь;
- **Object Storage**: bucket для приложения, сервисный аккаунт и статический ключ доступа;
- **Lockbox**: секрет с параметрами приложения (БД и S3).

Вся конфигурация лежит в каталоге [`terraform/`](terraform/). Состояние Terraform хранится в Object Storage и в репозиторий не попадает.

## Требования к рабочей системе

- Linux, macOS или Windows с WSL2
- [Terraform](https://developer.hashicorp.com/terraform/install) **>= 1.11** (нужна опция `use_lockfile` в S3-бэкенде)
- [Yandex Cloud CLI (`yc`)](https://yandex.cloud/ru/docs/cli/quickstart#install)
- `make`
- `kubectl` для работы с кластером после создания
- Аккаунт в Yandex Cloud с созданными облаком и каталогом и правами на создание ресурсов (`admin` на каталог либо набор ролей на сеть, Kubernetes, PostgreSQL, Object Storage, Lockbox и IAM)

> Если `registry.terraform.io` недоступен, используйте [зеркало Яндекса](https://yandex.cloud/ru/blog/posts/2022/03/terraform-and-packer). Создайте файл `~/.terraformrc`:
>
> ```hcl
> provider_installation {
>   network_mirror {
>     url     = "https://terraform-mirror.yandexcloud.net/"
>     include = ["registry.terraform.io/*/*"]
>   }
>   direct {
>     exclude = ["registry.terraform.io/*/*"]
>   }
> }
> ```

## Подготовка (выполняется один раз)

### 1. Настройка и аутентификация `yc`

```bash
yc init
```

Команда запросит авторизацию, облако, каталог и зону по умолчанию (`ru-central1-a`).

### 2. Бакет для состояния Terraform

Бэкенд должен существовать до `terraform init`, поэтому его создают вручную. Имя бакета должно совпадать со значением `bucket` в `terraform/backend.tf`.

```bash
# сервисный аккаунт для доступа Terraform к состоянию
yc iam service-account create --name tf-backend-sa

# роль на каталог (подставьте свои значения)
yc resource-manager folder add-access-binding <folder-id> \
  --role storage.editor \
  --subject serviceAccount:<tf-backend-sa-id>

# статический ключ: сохраните key_id и secret, secret показывается один раз
yc iam access-key create --service-account-name tf-backend-sa

# сам бакет
yc storage bucket create --name <имя-бакета-из-backend.tf>
```

### 3. Файлы с секретами

Оба файла перечислены в `.gitignore` (маска `secret.*`) и не должны попадать в репозиторий.

`terraform/secret.backend.tfvars` — доступ к бакету состояния:

```hcl
key        = "terraform.tfstate"      # путь к файлу состояния внутри бакета
access_key = "<key_id из шага 2>"
secret_key = "<secret из шага 2>"
```

Шаблон лежит в `terraform/example.secret.backend.tfvars`.

### 4. Токен для провайдера Yandex

Провайдер берёт IAM-токен из переменной окружения `YC_TOKEN`.

Рекомендуется (в том числе самим Яндексом) работать не от личного аккаунта, а от **сервисного аккаунта через имперсонацию**: у Terraform остаются только явно выданные права, а долгоживущие ключи сервисного аккаунта создавать не нужно.

Подготовка (один раз):

1. Создайте сервисный аккаунт для Terraform (например, `tf-sa`) и выдайте ему на каталог роли, достаточные для создания всех ресурсов проекта. Конфигурация создаёт сервисные аккаунты и назначает роли, поэтому потребуются и права на управление доступом (например, `admin` на каталог).
2. Выдайте своему пользователю роль `iam.serviceAccounts.tokenCreator` на этот сервисный аккаунт.

Получение токена от имени сервисного аккаунта:

```bash
export YC_TOKEN=$(yc iam create-token --impersonate-service-account-id <tf-sa-id>)
```

Токен живёт ограниченное время, поэтому при ошибках аутентификации просто получите новый.

> Для быстрых экспериментов можно использовать токен личного аккаунта: `yc iam create-token`. Для постоянной работы лучше имперсонация.

## Работа с инфраструктурой

Все команды выполняются из корня репозитория:

| Команда | Что делает |
|---------|-----------|
| `make init` | Инициализация проекта и бэкенда (`-backend-config=secret.backend.tfvars`) |
| `make format` | Форматирование `.tf`-файлов (`terraform fmt`) |
| `make validate` | Проверка конфигурации (`terraform validate`) |
| `make plan` | План изменений (`-var-file=secret.tfvars`) |
| `make apply` | Применение изменений (`-var-file=secret.tfvars`) |
| `make output` | Вывод значений outputs |
| `make destroy` | Удаление всей инфраструктуры (`-var-file=secret.tfvars`) |

Типичный порядок:

```bash
export YC_TOKEN=$(yc iam create-token --impersonate-service-account-id <tf-sa-id>)
make init
make validate
make plan
make apply
```

Создание кластера Kubernetes и PostgreSQL занимает несколько минут.

### Удаление

```bash
make destroy
```

Бакет состояния и сервисный аккаунт `tf-backend-sa` из шага 2 создавались вручную и удаляются вручную.

## Outputs

| Output | Описание | Чувствительный |
|--------|----------|:--:|
| `k8s_cluster_id` | ID кластера Kubernetes | нет |
| `k8s_node_group_id` | ID группы нод | нет |
| `cluster_endpoint` | Внешний адрес API кластера | да |
| `cluster_ca_certificate` | CA-сертификат кластера | да |
| `db_connection_string` | JDBC-строка подключения к PostgreSQL | да |
| `s3_bucket` | Имя bucket приложения | нет |
| `s3_access_key` | Access key для S3 | да |
| `s3_secret_key` | Secret key для S3 | да |
| `lockbox_secret_id` | ID секрета Lockbox | нет |

Значения с пометкой «чувствительный» не печатаются в списке `make output`. Получить конкретное значение:

```bash
cd terraform
terraform output -raw db_connection_string
terraform output -raw s3_secret_key
```

## Доступ к кластеру Kubernetes (kubeconfig)

Токен в outputs не выдаётся, так как он недолговечен. Вместо этого kubeconfig формируется через `yc`, который сам подставляет актуальный токен:

```bash
yc managed-kubernetes cluster get-credentials \
  $(cd terraform && terraform output -raw k8s_cluster_id) --external

kubectl get nodes
```

Адрес API и CA-сертификат кластера также доступны в outputs `cluster_endpoint` и `cluster_ca_certificate`, если нужно собрать kubeconfig вручную.

## PostgreSQL: параметры подключения

| Параметр | Значение |
|----------|----------|
| Хост | FQDN хоста `pg-host-a` (см. `db_connection_string`) |
| Порт | `6432` (пулер соединений) |
| База данных | `app-db` |
| Пользователь | `app` |
| Пароль | генерируется `random_password`, хранится в Lockbox (`SPRING_DATASOURCE_PASSWORD`) |
| SSL | `sslmode=require` (включён в строку подключения) |

Публичного IP у БД нет. Входящие подключения на порт 6432 разрешены только из подсети нод Kubernetes, то есть из подов кластера. С рабочей машины напрямую подключиться нельзя.

## Lockbox

Секрет `app-secret` содержит параметры приложения. ID секрета доступен в output `lockbox_secret_id`.

| Ключ | Содержимое |
|------|-----------|
| `SPRING_DATASOURCE_URL` | JDBC-строка подключения |
| `SPRING_DATASOURCE_USERNAME` | Пользователь БД |
| `SPRING_DATASOURCE_PASSWORD` | Пароль БД |
| `STORAGE_S3_ACCESSKEY` | Access key для S3 |
| `STORAGE_S3_SECRETKEY` | Secret key для S3 |

Посмотреть значение (нужны права на чтение секрета):

```bash
yc lockbox payload get \
  --id $(cd terraform && terraform output -raw lockbox_secret_id) \
  --key SPRING_DATASOURCE_PASSWORD
```

## Безопасность

- Состояние Terraform хранится только в Object Storage и не коммитится. Оно содержит пароль БД и ключи S3, поэтому доступ к бакету состояния должен быть ограничен.
- Файлы `secret.*` исключены из git через `.gitignore`.
- Файл `.terraform.lock.hcl` коммитится, чтобы версии провайдеров были воспроизводимы.
