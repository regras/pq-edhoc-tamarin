IMAGE ?= pq-edhoc-tamarin:1.0.0
DOCKER_USER ?= $(shell id -u):$(shell id -g)

.PHONY: build reproduce core fs-kci versions validate check-models clean

build: check-models
	docker build --tag "$(IMAGE)" .

reproduce:
	mkdir -p results
	docker run --rm --init \
		--user "$(DOCKER_USER)" \
		--env HOME=/tmp \
		--volume "$(CURDIR)/results:/artifact/results" \
		"$(IMAGE)" all

core:
	mkdir -p results
	docker run --rm --init \
		--user "$(DOCKER_USER)" \
		--env HOME=/tmp \
		--volume "$(CURDIR)/results:/artifact/results" \
		"$(IMAGE)" core

fs-kci:
	mkdir -p results
	docker run --rm --init \
		--user "$(DOCKER_USER)" \
		--env HOME=/tmp \
		--volume "$(CURDIR)/results:/artifact/results" \
		"$(IMAGE)" fs-kci

versions:
	mkdir -p results
	docker run --rm --init \
		--user "$(DOCKER_USER)" \
		--env HOME=/tmp \
		--volume "$(CURDIR)/results:/artifact/results" \
		"$(IMAGE)" versions

validate:
	./scripts/validate-results.sh all

check-models:
	sha256sum --check --strict SHA256SUMS

clean:
	rm -f results/*.log
