.PHONY: list
list:
	@cat $(firstword $(MAKEFILE_LIST)) | grep -e '^[^#.][a-zA-Z0-9_]*:$$' | cut -d ':' -f 1 | grep -v "$(firstword $(MAKEFILE_LIST))" | sort

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

.PHONY: test
test: shfmt lint
