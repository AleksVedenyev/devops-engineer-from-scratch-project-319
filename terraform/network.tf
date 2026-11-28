# ========================================================
# Создаем сеть
# ========================================================

resource "yandex_vpc_network" "k8s_network" {
  name = "k8s-network"
}

# ========================================================
# Создаем подсети
# ========================================================

resource "yandex_vpc_subnet" "k8s_subnet_master" {
  name           = "k8s-subnet-master"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.k8s_network.id
  v4_cidr_blocks = [local.k8s_subnet_master_cidr]
}

resource "yandex_vpc_subnet" "k8s_subnet_node" {
  name           = "k8s-subnet-node"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.k8s_network.id
  v4_cidr_blocks = [local.k8s_subnet_node_cidr]
  route_table_id = yandex_vpc_route_table.k8s_rt.id
}

resource "yandex_vpc_subnet" "pg_subnet" {
  name           = "pg-subnet"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.k8s_network.id
  v4_cidr_blocks = [local.pg_subnet_cidr]
}

# ========================================================
# Создаем NAT-шлюз и таблицу маршрутизации
# ========================================================

resource "yandex_vpc_gateway" "k8s_nat_gateway" {
  name = "k8s-nat-gateway"
  shared_egress_gateway {}
}

resource "yandex_vpc_route_table" "k8s_rt" {
  name       = "k8s-rt"
  network_id = yandex_vpc_network.k8s_network.id

  static_route {
    destination_prefix = local.anywhere_cidr
    gateway_id         = yandex_vpc_gateway.k8s_nat_gateway.id
  }
}

# ========================================================
# Создаем и настраиваем группы безопасности для k8s
# ========================================================

resource "yandex_vpc_security_group" "k8s-cluster-nodegroup-traffic" {
  name        = "k8s-cluster-nodegroup-traffic"
  description = "Служебный трафик для кластера и групп узлов"
  network_id  = yandex_vpc_network.k8s_network.id
  ingress {
    description       = "Правило для проверок состояния сетевого балансировщика нагрузки."
    from_port         = 0
    to_port           = 65535
    protocol          = "TCP"
    predefined_target = "loadbalancer_healthchecks"
  }
  ingress {
    description       = "Правило для входящего служебного трафика между мастером и узлами."
    from_port         = 0
    to_port           = 65535
    protocol          = "ANY"
    predefined_target = "self_security_group"
  }
  ingress {
    description    = "Правило для проверки работоспособности узлов с помощью ICMP-запросов из подсетей внутри Yandex Cloud."
    protocol       = "ICMP"
    v4_cidr_blocks = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]
  }
  egress {
    description       = "Правило для исходящего служебного трафика между мастером и узлами."
    from_port         = 0
    to_port           = 65535
    protocol          = "ANY"
    predefined_target = "self_security_group"
  }
}

resource "yandex_vpc_security_group" "k8s-nodegroup-traffic" {
  name        = "k8s-nodegroup-traffic"
  description = "Служебный трафик для групп узлов"
  network_id  = yandex_vpc_network.k8s_network.id
  ingress {
    description = "Правило для входящего трафика, разрешающее передачу трафика между подами и сервисами."
    from_port   = 0
    to_port     = 65535
    protocol    = "ANY"
    v4_cidr_blocks = [
      local.k8s_pod_cidr,
      local.k8s_service_cidr
    ]
  }
  egress {
    description    = "Правило для исходящего трафика, разрешающее узлам в группе узлов подключаться к внешним ресурсам."
    from_port      = 0
    to_port        = 65535
    protocol       = "ANY"
    v4_cidr_blocks = [local.anywhere_cidr]
  }
}

resource "yandex_vpc_security_group" "k8s-services-access" {
  name        = "k8s-services-access"
  description = "Подключение к сервисам из интернета"
  network_id  = yandex_vpc_network.k8s_network.id
  ingress {
    description    = "Правило для входящего трафика, разрешающее подключение к сервисам."
    from_port      = 30000
    to_port        = 32767
    protocol       = "TCP"
    v4_cidr_blocks = [local.anywhere_cidr]
  }
}

resource "yandex_vpc_security_group" "k8s-cluster-traffic" {
  name        = "k8s-cluster-traffic"
  description = "Трафик для кластера."
  network_id  = yandex_vpc_network.k8s_network.id
  ingress {
    description    = "Правило для входящего трафика, разрешающее доступ к API Kubernetes (порт 443)."
    port           = 443
    protocol       = "TCP"
    v4_cidr_blocks = [local.anywhere_cidr]
  }
  ingress {
    description    = "Правило для входящего трафика, разрешающее доступ к API Kubernetes (порт 6443)."
    port           = 6443
    protocol       = "TCP"
    v4_cidr_blocks = [local.anywhere_cidr]
  }
  egress {
    description    = "Правило для исходящего трафика, разрешающее передачу трафика между мастером и подами metric-server."
    port           = 4443
    protocol       = "TCP"
    v4_cidr_blocks = [local.k8s_pod_cidr]
  }
  egress {
    description    = "Правило для исходящего трафика, разрешающее подключение мастера к NTP-серверам для синхронизации времени."
    port           = 123
    protocol       = "UDP"
    v4_cidr_blocks = [local.anywhere_cidr]
  }
}

# ========================================================
# Создаем и настраиваем группы безопасности для PostgreSQL
# ========================================================

resource "yandex_vpc_security_group" "pg_sg" {
  name       = "pg-sg"
  network_id = yandex_vpc_network.k8s_network.id

  ingress {
    description    = "PostgreSQL"
    port           = 6432
    protocol       = "TCP"
    v4_cidr_blocks = [local.k8s_subnet_node_cidr]
  }
  egress {
    description    = "Правило для исходящего трафика"
    from_port      = 0
    to_port        = 65535
    protocol       = "ANY"
    v4_cidr_blocks = [local.anywhere_cidr]
  }
}