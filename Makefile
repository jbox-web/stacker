#############
# Constants #
#############

PREFIX      ?= /usr/local
INSTALL_DIR  = $(PREFIX)/bin
SOURCE_FILE  = src/stacker.cr
OUTPUT_FILE  = bin/stacker
COMPILE_OPTS = --threads 4 --release --progress --error-trace
DOCKER_TAG   = jbox-web/stacker:latest

################
# Public tasks #
################

# This is the default task
all: help

stacker: ## Compile to development binary
	crystal build --threads 4 -o $(OUTPUT_FILE) $(SOURCE_FILE)

stacker-release: clean deps-prod ## Compile to production binary
	crystal build $(COMPILE_OPTS) -o $(OUTPUT_FILE) $(SOURCE_FILE)

stacker-static: clean deps-prod ## Compile to production binary (static mode)
	crystal build $(COMPILE_OPTS) --static -o $(OUTPUT_FILE) $(SOURCE_FILE)

spec: ## Run Crystal spec
	@if tty -s; then \
	  crystal spec --verbose; \
	else \
	  crystal spec; \
	fi

clean: ## Cleanup environment
	rm -rf bin/*
	rm -rf lib/

deps: ## Install development dependencies
	shards install

deps-prod: ## Install production dependencies
	shards install --production

install: ## Install stacker in $(INSTALL_DIR)
	cp $(OUTPUT_FILE) $(INSTALL_DIR)/stacker

uninstall: ## Uninstall stacker from $(INSTALL_DIR)
	rm -f $(INSTALL_DIR)/stacker

docker: ## Build Docker image
	docker build . -t $(DOCKER_TAG)

doc: ## Generate Stacker documentation
	rm -rf docs
	crystal doc

.PHONY: all stacker stacker-release stacker-static spec clean deps deps-prod install uninstall docker doc

#################
# Private tasks #
#################

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
