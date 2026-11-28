apiVersion: v1
kind: Secret
metadata:
  name: app-secret
  namespace: app
type: Opaque
stringData:
  SPRING_DATASOURCE_PASSWORD: "${SPRING_DATASOURCE_PASSWORD}"
  STORAGE_S3_ACCESSKEY: "${STORAGE_S3_ACCESSKEY}"
  STORAGE_S3_SECRETKEY: "${STORAGE_S3_SECRETKEY}"