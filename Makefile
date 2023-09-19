all: lint

SHELL := /bin/bash

export SUPER_LINTER_VERSION='v4.8.5'
export EXCLUDED_DIRECTORY='00_compile_tpcds/t.*/.*'

.PHONY: centos
centos:
	sudo yum -y install epel-release
	sudo yum install ShellCheck

.PHONY: macos
macos:
	brew install shellcheck
	brew install shfmt

.PHONY: shfmt
shfmt:
	find . -name "*.sh" -not -path './00_compile_tpcds/t*' | xargs shfmt -d -i 2 -sr -w

.PHONY: lint
lint:
	find . -name "*.sh" -not -path './00_compile_tpcds/t*' | grep -v 'tpcds_variables.sh' | xargs shellcheck -S warning

.PHONY: super-linter
super-linter:
	docker run --rm \
		-e VALIDATE_BASH=true \
		-e VALIDATE_BASH_EXEC=true \
		-e RUN_LOCAL=true \
		-e LOG_LEVEL=ERROR \
		-e FILTER_REGEX_EXCLUDE=$(EXCLUDED_DIRECTORY) \
		-v ${PWD}:/tmp/lint \
		github/super-linter:slim-$(SUPER_LINTER_VERSION)

.PHONY: test
test: shfmt lint super-linter
