.PHONY: init format validate plan apply output destroy

init:
	@cd terraform && terraform init -backend-config=secret.backend.tfvars

format:
	@cd terraform && terraform fmt

validate:
	@cd terraform && terraform validate

plan:
	@@cd terraform && terraform plan

apply:
	@cd terraform && terraform apply

output:
	@cd terraform && terraform output

destroy:
	@cd terraform && terraform destroy