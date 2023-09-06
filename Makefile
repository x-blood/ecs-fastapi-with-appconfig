COMMIT_HASH := `git rev-parse --short HEAD`

echo_env:
	@echo $(M_AWS_ACCOUNT_ID)
	@echo $(M_AWS_REGION)
	@echo $(TF_S3_BUCKET)
	@echo $(TF_S3_KEY)
	@echo $(TF_VAR_vpc_id)
	@echo $(TF_VAR_subnet_id_public_a)
	@echo $(TF_VAR_subnet_id_public_c)
	@echo $(COMMIT_HASH)

tf_tagging_tfstate:
	aws s3api put-object-tagging --bucket $(TF_S3_BUCKET) --key $(TF_S3_KEY) --tagging 'TagSet=[{Key=DoNotNuke,Value=true}]'

tf_init:
	cd iac/terraform && terraform init -backend-config="bucket=$(TF_S3_BUCKET)" -backend-config="key=$(TF_S3_KEY)" -backend-config="region=$(M_AWS_REGION)"

tf_plan:
	cd iac/terraform && terraform plan

tf_apply:
	cd iac/terraform && terraform apply

ecspresso_deploy:
	cd iac/ecspresso && ecspresso deploy

ecspresso_scalein_0:
	cd iac/ecspresso && ecspresso scale --tasks=0

app_build_and_push:
	docker build -t fastapi_appconfig .
	aws ecr get-login-password --region ap-northeast-1 | docker login --username AWS --password-stdin $(M_AWS_ACCOUNT_ID).dkr.ecr.ap-northeast-1.amazonaws.com/yassan-fa-ac-repository
	docker tag fastapi_appconfig:latest $(M_AWS_ACCOUNT_ID).dkr.ecr.ap-northeast-1.amazonaws.com/yassan-fa-ac-repository:$(COMMIT_HASH)
	docker push $(M_AWS_ACCOUNT_ID).dkr.ecr.ap-northeast-1.amazonaws.com/yassan-fa-ac-repository:$(COMMIT_HASH)
	echo COMMIT_HASH=$(COMMIT_HASH)
