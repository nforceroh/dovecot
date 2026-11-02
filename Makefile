# Local build and test only — CI is the sole publisher.
# Shared pipelines: https://github.com/nforceroh/.github
SHELL := /bin/bash
IMAGE ?= ghcr.io/nforceroh/dovecot
TAG   ?= dev

.PHONY: build test run

build:
	docker build \
		--build-arg BUILD_DATE="$(shell date -u +'%Y-%m-%dT%H:%M:%SZ')" \
		--build-arg VERSION="$(TAG)" \
		--tag $(IMAGE):$(TAG) .

test: build
	./tests/run_tests.sh "$(IMAGE):$(TAG)"

run: build
	docker run --rm -it \
		-p 24:24 \
		-p 110:110 \
		-p 143:143 \
		-p 993:993 \
		-p 3333:3333 \
		-p 4190:4190 \
		-p 12345:12345 \
		$(IMAGE):$(TAG)
