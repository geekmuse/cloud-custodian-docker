VERSION ?= 0.8.33.0
REGION ?= us-east-1

.DEFAULT_TARGET: help-cmds


.PHONY: help-cmds
help-cmds:		## This help.
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'


.PHONY: dkr-deps
dkr-deps:		## Locally downloads all code and unpackages it in prep for building a container image.
	@wget -O custodian.tar.gz "https://github.com/cloud-custodian/cloud-custodian/archive/$(VERSION).tar.gz"
	@tar xvzf custodian.tar.gz
	@mv "cloud-custodian-$(VERSION)" cloud-custodian


.PHONY: dkr-clean
dkr-clean:		## Clean up all local deps.
	-rm -Rf custodian.tar.gz
	-rm -Rf cloud-custodian


.PHONY: dkr-build
dkr-build:		## Builds a Docker image and tags it.
	@docker build -t "cloud-custodian:$(VERSION)" .
	@docker tag "cloud-custodian:$(VERSION)" "cloud-custodian:$(VERSION)"


.PHONY: dkr-build-clean		##	(clean deps build)
dkr-build-clean: clean deps build


.PHONY: dkr-build-nocache
dkr-build-nocache:		## Builds Docker image using "--no-cache" and tags it.
	@docker build --no-cache -t "cloud-custodian:$(VERSION)" .
	@docker tag "cloud-custodian:$(VERSION)" "cloud-custodian:$(VERSION)"


.PHONY: dkr-tag-latest
dkr-tag-latest:			## Tags `VERSION` image with "latest".
	@docker tag "cloud-custodian:$(VERSION)" cloud-custodian:latest


.PHONY: dkr-push
dkr-push:				## Push image with tag `VERSION` to ECR.		
	@$$(aws ecr get-login --no-include-email --region us-east-1)
	@docker tag "cloud-custodian:$(VERSION)" "$$(aws sts get-caller-identity --query 'Account' --output text).dkr.ecr.$(REGION).amazonaws.com/cloud-custodian:$(VERSION)"
	@docker push "$$(cd terraform && terraform output -json | jq -r '.c7n_docker_repo_url.value'):$(VERSION)"


.PHONY: dkr-push-latest
dkr-push-latest:		## Tag image of version `VERSION` with `latest` tag and push to ECR.			
	@$$(aws ecr get-login --no-include-email --region us-east-1)
	@docker tag "cloud-custodian:$(VERSION)" "$$(aws sts get-caller-identity --query 'Account' --output text).dkr.ecr.$(REGION).amazonaws.com/cloud-custodian:latest"
	@docker push  "$$(cd terraform && terraform output -json | jq -r '.c7n_docker_repo_url.value'):latest"


.PHONY: cust-lambda
cust-lambda:			## Runs "c7n-mailer" with "--update-lambda" flag.  Requires AWS environment credentials.
	@docker run \
		-e AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY_ID}" \
		-e AWS_SECRET_ACCESS_KEY="${AWS_SECRET_ACCESS_KEY}" \
		-e AWS_DEFAULT_REGION="$(REGION)" \
		-v "$(CURDIR)/logs:/tmp" \
		"cloud-custodian:$(VERSION)" \
		-c "/usr/local/bin/c7n-mailer --config mailer.yml --update-lambda"


.PHONY: cust-run
cust-run:				## Run custodian.  Requires AWS environment credentials.
	@docker run \
		-e AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY_ID}" \
		-e AWS_SECRET_ACCESS_KEY="${AWS_SECRET_ACCESS_KEY}" \
		-e AWS_DEFAULT_REGION="$(REGION)" \
		-v "$(CURDIR)/logs:/tmp" \
		"cloud-custodian:$(VERSION)" \
		-c "/usr/local/bin/custodian run --output-dir=/tmp policy.yml; /usr/local/bin/c7n-mailer --config mailer.yml --run"


.PHONY: cust-dryrun
cust-dryrun:			## Run custodian in dry-run mode.  Requires AWS environment credentials.
	@docker run \
		-e AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY_ID}" \
		-e AWS_SECRET_ACCESS_KEY="${AWS_SECRET_ACCESS_KEY}" \
		-e AWS_DEFAULT_REGION="$(REGION)" \
		-v "$(CURDIR)/logs:/tmp" \
		"cloud-custodian:$(VERSION)" \
		-c "/usr/local/bin/custodian run --dry-run --output-dir=/tmp policy.yml; /usr/local/bin/c7n-mailer --config mailer.yml --run"
