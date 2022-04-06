all: lint

SHELL := /bin/bash

export SUPER_LINTER_VERSION='v4.8.5'

.PHONY: lint
lint:
	docker run --rm \
		-e VALIDATE_BASH=true \
		-e VALIDATE_BASH_EXEC=true \
		-e RUN_LOCAL=true \
		-e LOG_LEVEL=ERROR \
		-e FILTER_REGEX_EXCLUDE='00_compile_tpcds/t.*/.*' \
		-v ${PWD}:/tmp/lint \
		gcr.io/gp-virtual/super-linter:slim-$(SUPER_LINTER_VERSION)
