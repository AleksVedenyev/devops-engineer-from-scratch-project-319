.PHONY: init format validate plan apply output destroy configmap secret k8s-deploy rollout port-forward
TF_DIR := terraform
K8S_DIR := k8s
NAMESPACE := app

init:
	@cd $(TF_DIR) && terraform init -backend-config=secret.backend.tfvars

format:
	@cd $(TF_DIR) && terraform fmt

validate:
	@cd $(TF_DIR) && terraform validate

plan:
	@cd $(TF_DIR) && terraform plan

apply:
	@cd $(TF_DIR) && terraform apply

output:
	@cd $(TF_DIR) && terraform output

destroy:
	@cd $(TF_DIR) && terraform destroy

configmap:
	@cd $(TF_DIR) && \
	LOCKBOX_ID=$$(terraform output -raw lockbox_secret_id) && \
	SPRING_DATASOURCE_URL=$$(yc lockbox payload get --id $$LOCKBOX_ID --key SPRING_DATASOURCE_URL) && \
	SPRING_DATASOURCE_USERNAME=$$(yc lockbox payload get --id $$LOCKBOX_ID --key SPRING_DATASOURCE_USERNAME) && \
	STORAGE_S3_BUCKET=$$(terraform output -raw s3_bucket) && \
	export SPRING_DATASOURCE_URL SPRING_DATASOURCE_USERNAME STORAGE_S3_BUCKET && \
	envsubst '$$SPRING_DATASOURCE_URL $$SPRING_DATASOURCE_USERNAME $$STORAGE_S3_BUCKET' < ../$(K8S_DIR)/app-configmap.yml.tpl | kubectl apply -f -

secret:
	@cd $(TF_DIR) && \
	LOCKBOX_ID=$$(terraform output -raw lockbox_secret_id) && \
	SPRING_DATASOURCE_PASSWORD=$$(yc lockbox payload get --id $$LOCKBOX_ID --key SPRING_DATASOURCE_PASSWORD) && \
	STORAGE_S3_ACCESSKEY=$$(yc lockbox payload get --id $$LOCKBOX_ID --key STORAGE_S3_ACCESSKEY) && \
	STORAGE_S3_SECRETKEY=$$(yc lockbox payload get --id $$LOCKBOX_ID --key STORAGE_S3_SECRETKEY) && \
	export SPRING_DATASOURCE_PASSWORD STORAGE_S3_ACCESSKEY STORAGE_S3_SECRETKEY && \
	envsubst '$$SPRING_DATASOURCE_PASSWORD $$STORAGE_S3_ACCESSKEY $$STORAGE_S3_SECRETKEY' < ../$(K8S_DIR)/app-secret.yml.tpl | kubectl apply -f -

k8s-deploy:
	@cd $(K8S_DIR) && kubectl apply -f app-namespace.yml
	@$(MAKE) configmap
	@$(MAKE) secret
	@cd $(K8S_DIR) && kubectl apply -f app-deployment.yml && \
	kubectl apply -f app-service.yml && \
	kubectl rollout status deployment/app-deployment -n $(NAMESPACE) --timeout=5m

rollout:
	kubectl rollout restart deployment/app-deployment -n $(NAMESPACE)

port-forward:
	kubectl port-forward deployment/app-deployment 8080:8080 -n $(NAMESPACE)