# Prerequisites using this incude file:
#
# == Setup local Makefile ==
# Create `Makefile` with the following content:
# OWNER = Owner of the service
# PROJECT = somename
# REGION = eu-west-1 # Default region if not specified
# include ../relative/path/to/tools/terraform.mk
#
#
# == Configure state backend ==
# Create `terraform.tf` with the following content:
# terraform {
#   backend "s3" {
#     profile = "aws-profile"
#     region  = "eu-west-1"
#     bucket  = "s3-bucket"
#   }
# }

.PHONY: help credentials

REGION ?= "eu-west-1"
ACCOUNT_POSTFIX ?= ""

PLANFILE = "$(ENVIRONMENT)-$(PROJECT).plan"
ifndef OWNER
	STATEFILE = $(PROJECT)/$(REGION).tfstate
else
	STATEFILE = "$(OWNER)/$(PROJECT)/$(REGION).tfstate"
endif
AWS_PROFILE ?= "aws-profile"

UNAME_S ?= $(shell uname -s)
STAT_COMMAND = "$(shell if [ "$(UNAME_S)" = 'Linux' ]; then echo "stat -c '%Y'"; else echo "stat -f'%m'"; fi)"

export AWS_PROFILE

help:
	@echo "Select which environment you work on by setting ENVIRONMENT=(test|prod)"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | sed -e 's/^[^:]*:\(.*\)/\1/' | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'

check-env:
	@if [ -z $(PROJECT) ]; then echo "PROJECT was not set" ; exit 10 ; fi
	@if [ -z $(ENVIRONMENT) ]; then echo "ENVIRONMENT was not set" ; exit 10 ; fi

version:
	@terraform version

init-backend: check-env ## Initialize state backend
	@rm -f .terraform/terraform.tfstate
	@terraform init --force-copy --backend-config="key=$(STATEFILE)" $(UPGRADE)
	@terraform get -update=true

init: init-backend ## Initialize and select environment
	@if [ "$(ENVIRONMENT)" != "$(shell terraform workspace show)" ]; then \
		if ! terraform workspace list | grep -q "$(ENVIRONMENT)"; then \
			terraform workspace new "$(ENVIRONMENT)"; \
		else \
			terraform workspace select "$(ENVIRONMENT)"; \
		fi \
	fi

upgrade: UPGRADE="-upgrade" ## Will upgrade provider to the latest acceptable version
upgrade: init

plan:: init ## Runs a plan
	@rm -f "$(PLANFILE)"
	@terraform plan -input=false -refresh=true $(PLAN_ARGS) -out="$(PLANFILE)"

plan-destroy: init ## Runs a plan to destroy
	@terraform plan -destroy -input=false -refresh=true $(PLAN_ARGS) -out="$(PLANFILE)"

show: init ## Shows a module
	@terraform show

#graph: ## Runs the terraform grapher
#	@rm -f graph.png
#	@terraform graph -draw-cycles -module-depth=-1 | dot -Tpng > graph.png
#	@open graph.png

apply:: init ## Applies a planned state.
	@if [ ! -r "$(PLANFILE)" ]; then echo "You need to plan first!" ; exit 14; fi
	@if [ $$(($(shell date +'%s')-$(shell "$(STAT_COMMAND)" "$(PLANFILE)"))) -gt 180 ]; then echo "Plan file is older than 3 minutes; Aborting!" ; exit 15; fi
	@terraform apply -input=true -refresh=true "$(PLANFILE)"

output: init ## Show outputs of a module or the entire state.
	@if [ -z $(MODULE) ]; then terraform output ; else terraform output -module=$(MODULE) ; fi
