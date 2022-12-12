.PHONY: clean
clean:
	find . -type f -name '.terraform.lock.hcl' -exec rm -rf {} \;
	find . -type d -name '.terraform' -exec rm -rf {} +

.PHONY: init
init: .env
	docker-compose run --rm terraform-utils sh -c 'terragrunt run-all init'


.PHONY: plan
plan: .env init
	docker-compose run --rm terraform-utils sh -c 'terragrunt run-all plan'


.PHONY: apply
apply: .env init
	docker-compose run --rm terraform-utils sh -c 'terragrunt run-all apply'


.PHONY: clean-dir
# For local development, deletes existing terraform files so new plugins can be pulled down and installed
clean-dir:
	find $(dir) -type f -name '.terraform.lock.hcl' -exec rm -rf {} \;
	find $(dir) -type d -name '.terraform' -exec rm -rf {} +

.PHONY: init-dir
# For local development, pass in the directory you want to process
init-dir: .env clean-dir
	docker-compose run --rm terraform-utils sh -c 'terraform -chdir=$(dir) init'

.PHONY: plan-dir
# For local development, pass in the directory you want to process
plan-dir: .env init-dir
	docker-compose run --rm terraform-utils sh -c 'terraform -chdir=$(dir) plan'

.PHONY: apply-dir
# For local development, pass in the directory you want to process
apply-dir: .env
	docker-compose run --rm terraform-utils sh -c 'terraform -chdir=$(dir) apply'


.PHONY: apply-test
apply-test: .env init
	docker-compose run --rm terraform-utils sh -c 'cd ./test; terragrunt run-all apply'
	
# test target to print out env vars for debugging
.PHONY: test
test: .env
	printenv
	docker-compose run --rm terraform-utils sh -c 'printenv'

.env:
	touch .env
	docker-compose run --rm envvars validate
	docker-compose run --rm envvars envfile --overwrite
.PHONY: .env
