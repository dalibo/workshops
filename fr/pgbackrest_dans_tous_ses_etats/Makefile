ifdef env
	EXTRA_ARGS:=--env=$(env)
endif
ifdef provshell
	EXTRA_ARGS:=$(EXTRA_ARGS) --shell=$(provshell)
endif

SHELL:=/bin/bash
.PHONY: help
help: ## Display callable targets.
	@echo "Reference card for usual actions."
	@echo "Here are available targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.DEFAULT_GOAL := help

CURRENT_DIR=$(shell pwd)

.PHONY: all ## Up all VM and provision them.
all: up provision## Up all VM and provision them.

.PHONY: init ## Init ansible roles and collections.
init: ## Init ansible roles and collections.
	$(MAKE) -C ../ansible.d init

.PHONY: up ## Up all VM. Also init ansible roles and collections.
up: ## Up all VM. Also init ansible roles and collections.
	vagrant $(EXTRA_ARGS) up --no-provision

.PHONY: reset ## Reset all VM. Destroy them and create them.
reset: destroy all ## Reset all VM. Destroy them and create them.

.PHONY: provision ## Provision all VM. Also init ansible roles and collections.
provision: ## Provision all VM. Also init ansible roles and collections.
	vagrant upload install_pg.sh install.sh pg1
	vagrant upload install_pgbackrest.sh install.sh pgbackrest1
	vagrant $(EXTRA_ARGS) provision
	vagrant ssh -c 'bash install.sh' pg1
	vagrant ssh -c 'bash install.sh' pgbackrest1



.PHONY: destroy ## Destroy all VM.
destroy: ## Destroy all VM.
	vagrant $(EXTRA_ARGS) destroy --force

.PHONY: update ## Update all box.
update: ## Update all box.
	vagrant $(EXTRA_ARGS) box update