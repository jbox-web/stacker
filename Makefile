#############
# Constants #
#############

PREFIX ?= /usr/local
INSTALL_DIR=$(PREFIX)/bin

################
# Public tasks #
################

# This is the default task
all: help

stacker: ## Compile to development binary
	crystal build --threads 4 -o bin/stacker src/stacker.cr

stacker-release: clean deps-prod ## Compile to production binary
	crystal build --threads 4 --release -o bin/stacker src/stacker.cr

stacker-static: clean deps-prod ## Compile to production binary (static mode)
	crystal build --threads 4 --release --static -o bin/stacker src/stacker.cr

spec: ## Run Crystal spec
	crystal spec

clean: ## Cleanup environment
	rm -rf bin/*
	rm -rf lib/

deps: ## Install development dependencies
	shards install

deps-prod: ## Install production dependencies
	shards install --production

install: ## Install stacker in $(INSTALL_DIR)
	cp bin/stacker $(INSTALL_DIR)/stacker

uninstall: ## Uninstall stacker from $(INSTALL_DIR)
	rm -f $(INSTALL_DIR)/stacker

.PHONY: all stacker stacker-release stacker-static spec clean deps deps-prod install uninstall

#################
# Private tasks #
#################

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
