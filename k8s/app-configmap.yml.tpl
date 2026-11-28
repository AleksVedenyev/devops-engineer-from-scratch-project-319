apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
  namespace: app
data:
  SPRING_PROFILES_ACTIVE: "prod"
  SPRING_DATASOURCE_URL: "${SPRING_DATASOURCE_URL}"
  SPRING_DATASOURCE_USERNAME: "${SPRING_DATASOURCE_USERNAME}"
  STORAGE_S3_BUCKET: "${STORAGE_S3_BUCKET}"
  STORAGE_S3_REGION: "ru-central1"
  STORAGE_S3_ENDPOINT: "https://storage.yandexcloud.net"
  MANAGEMENT_SERVER_PORT: "9090"