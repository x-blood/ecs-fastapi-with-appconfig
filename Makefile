COMMIT_HASH := `git rev-parse --short HEAD`

echo_env: ## setting env values
	@echo $(M_AWS_ACCOUNT_ID)
	@echo $(M_AWS_REGION)
	@echo $(TF_S3_BUCKET)
	@echo $(TF_S3_KEY)
	@echo $(TF_VAR_vpc_id)
	@echo $(TF_VAR_subnet_id_public_a)
	@echo $(TF_VAR_subnet_id_public_c)
	@echo $(TF_VAR_subnet_id_private_a)
	@echo $(TF_VAR_subnet_id_private_c)
	@echo $(TF_VAR_route_table_id_private_a)
	@echo $(TF_VAR_route_table_id_private_c)
	@echo $(CONTAINER_IMAGE_TAG)
	@echo $(COMMIT_HASH)

tf_tagging_tfstate: ## Tagging tfstate file
	aws s3api put-object-tagging --bucket $(TF_S3_BUCKET) --key $(TF_S3_KEY) --tagging 'TagSet=[{Key=DoNotNuke,Value=true}]'

tf_init: ## Terraform init
	cd iac/terraform && terraform init -backend-config="bucket=$(TF_S3_BUCKET)" -backend-config="key=$(TF_S3_KEY)" -backend-config="region=$(M_AWS_REGION)"

tf_plan: ## Terraform plan
	cd iac/terraform && terraform plan

tf_apply: ## Terraform apply
	cd iac/terraform && terraform apply

ecspresso_deploy: ## Deploy with ecspresso
	cd iac/ecspresso && ecspresso deploy

ecspresso_scalein_0: ## Scale In with ecspresso
	cd iac/ecspresso && ecspresso scale --tasks=0

app_build_and_push: ## Docker for Mac
	docker build --platform linux/amd64 -t fastapi_appconfig .
	aws ecr get-login-password --region ap-northeast-1 | docker login --username AWS --password-stdin $(M_AWS_ACCOUNT_ID).dkr.ecr.ap-northeast-1.amazonaws.com/yassan-fa-ac-repository
	docker tag fastapi_appconfig:latest $(M_AWS_ACCOUNT_ID).dkr.ecr.ap-northeast-1.amazonaws.com/yassan-fa-ac-repository:$(COMMIT_HASH)
	docker push $(M_AWS_ACCOUNT_ID).dkr.ecr.ap-northeast-1.amazonaws.com/yassan-fa-ac-repository:$(COMMIT_HASH)
	echo COMMIT_HASH=$(COMMIT_HASH)

create_pull_through_cache: ## Create Pull Through Cache
	aws ecr get-login-password --region ap-northeast-1 | docker login --username AWS --password-stdin $(M_AWS_ACCOUNT_ID).dkr.ecr.ap-northeast-1.amazonaws.com/ecr-public
	docker image pull $(M_AWS_ACCOUNT_ID).dkr.ecr.ap-northeast-1.amazonaws.com/ecr-public/aws-appconfig/aws-appconfig-agent:2.x

ecspresso_delete: ## Delete
	cd iac/ecspresso && ecspresso scale --tasks=0
	cd iac/ecspresso && ecspresso delete

ecr_clean: ## Delete All Container Images
	aws ecr describe-images --repository-name yassan-fa-ac-repository --query 'imageDetails[]' | jq 'sort_by(.imagePushedAt) | .[].imageTags[]' -r | head -n 1000 | xargs -I{} aws ecr batch-delete-image --repository-name yassan-fa-ac-repository --image-ids imageTag={}

tf_destroy: ## Destroy
	cd iac/terraform && terraform destroy

help: ## Display this help screen
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'
