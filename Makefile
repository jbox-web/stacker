################
# Public tasks #
################

# This is the default task
all: help

stacker: ## Compile to development binary
	crystal build --threads 4 -o bin/stacker src/stacker.cr

stacker-release: ## Compile to production binary
	crystal build --threads 4 --release -o bin/stacker src/stacker.cr

deps: ## Install dependencies
	shards install

spec: ## Run Crystal spec
	crystal spec

clean: ## Cleanup environment
	rm -rf bin/*
	rm -rf lib/
	$(MAKE) deps

.PHONY: all stacker stacker-release deps spec clean

#################
# Private tasks #
#################

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
