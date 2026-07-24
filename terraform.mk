PROJECT       ?= $(error PROJECT is not set)
PROJECT_DIR   ?= .
TF_WORK_DIR   ?= $(PROJECT_DIR)
TOFU          ?= $(shell which tofu)
PLANFILE       = $(PROJECT).plan
PULLFILE       = $(PROJECT).tfstate

ifdef STATE_REPO_URL
  STATEFILE = $(PROJECT)/$(PROJECT_DIR)/terraform.tfstate
  TF_BACKEND = terraform-backend-git git \
    -r $(STATE_REPO_URL) -s $(STATEFILE) -b master -d $(TF_WORK_DIR) \
    terraform --tf "$(TOFU)"
else
  TF_BACKEND = $(TOFU)
endif

.PHONY: help init plan apply show pull version

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | \
	  sed -e 's/^[^:]*:\(.*\)/\1/' | \
	  awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'

init: ## Initialize backend (local or remote per STATE_REPO_URL toggle)
	@rm -f .terraform/terraform.tfstate git_http_backend.auto.tf
ifdef STATE_REPO_URL
	$(info Remote state: $(STATE_REPO_URL)/$(STATEFILE))
else
	@echo ""
	@echo "*********************************************************************"
	@echo "*                                                                   *"
	@echo "*  WARNING: STATE_REPO_URL not set!                                 *"
	@echo "*                                                                   *"
	@echo "*  Using LOCAL state: example/terraform.tfstate                     *"
	@echo "*                                                                   *"
	@echo "*  Set STATE_REPO_URL for remote state via terraform-backend-git.   *"
	@echo "*  Example: export STATE_REPO_URL=https://github.com/org/state      *"
	@echo "*                                                                   *"
	@echo "*********************************************************************"
	@echo ""
endif
	@$(TF_BACKEND) init -reconfigure

plan: ## Run a plan
	@rm -f "$(PLANFILE)"
	@$(TF_BACKEND) plan -input=false -refresh=true -out="$(PLANFILE)"

apply: ## Apply planned changes
	@if [ ! -r "$(PLANFILE)" ]; then echo "Plan first!"; exit 14; fi
	@$(TF_BACKEND) apply -input=false -refresh=true "$(PLANFILE)"

show: ## Show state
	@$(TF_BACKEND) show

pull: ## Pull state to a file
ifdef STATE_REPO_URL
	@$(TF_BACKEND) state pull > "$(PULLFILE)" && echo "Saved state file to $(PULLFILE)"
else
	$(error pull requires STATE_REPO_URL (remote mode))
endif

version: ## Show tofu version
	@$(TOFU) version
