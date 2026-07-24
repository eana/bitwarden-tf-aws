TOFU ?= $(shell which tofu)

.PHONY: validate fmt lint docs

validate: ## Validate module
	$(TOFU) validate

fmt: ## Format terraform files
	$(TOFU) fmt -recursive

lint: ## Run tflint
	tflint

docs: ## Generate terraform-docs (regenerates README tables)
	terraform-docs markdown table . > README.md
