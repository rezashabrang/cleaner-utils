#* Variables
SHELL := /usr/bin/env bash
PYTHON := python

#* Docker variables
IMAGE := cleaning_utils
VERSION := latest

#* Poetry
.PHONY: poetry-download
poetry-download:
	curl -sSL https://raw.githubusercontent.com/python-poetry/poetry/master/install-poetry.py | $(PYTHON) -

.PHONY: poetry-remove
poetry-remove:
	curl -sSL https://raw.githubusercontent.com/python-poetry/poetry/master/install-poetry.py | $(PYTHON) - --uninstall

#* Installation
.PHONY: install
install:
	poetry lock -n && poetry export --without-hashes > requirements.txt
	poetry install -n
	-poetry run mypy --install-types --non-interactive ./


.PHONY: pre-commit-install
pre-commit-install:
	poetry run pre-commit install

#* Formatters
.PHONY: codestyle
codestyle:
	poetry run pyupgrade --exit-zero-even-if-changed --py38-plus **/*.py
	poetry run isort cleaning_utils/*.py --settings-path pyproject.toml ./
	poetry run black cleaning_utils/*.py --config pyproject.toml ./

.PHONY: formatting
formatting: codestyle
#* Linting
.PHONY: test
test:
	poetry run pytest -c pyproject.toml

.PHONY: extrabadges
extrabadges:
	$(SHELL) -c 'chmod u+x+r+w .shell/*.sh'
	$(SHELL) -c 'chmod u+x+r+w .shell/badges.sh; . .shell/badges.sh'

.PHONY: complexity
complexity:
	poetry run radon cc cleaning_utils --total-average

.PHONY: maintainability
maintainability:
	poetry run radon mi cleaning_utils

.PHONY: interrogate
interrogate:
	poetry run interrogate -v cleaning_utils

.PHONY: release
release:
	$(SHELL) -c 'chmod u+x+r+w .shell/release.sh; . .shell/release.sh'

.PHONY: coverage
coverage:
	poetry run pytest --cov-report html --cov cleaning_utils tests/

.PHONY: coverage-badge
coverage-badge:
	coverage-badge -o assets/images/coverage.svg -f

.PHONY: check-codestyle
check-codestyle:
	poetry run isort --diff --check-only --settings-path pyproject.toml cleaning_utils/*.py tests/*.py
	poetry run black --diff --check --config pyproject.toml cleaning_utils/*.py tests/*.py
	poetry run darglint --verbosity 2 cleaning_utils tests

.PHONY: mypy
mypy:
	poetry run mypy --install-types --non-interactive --config-file pyproject.toml ./

.PHONY: check-safety
check-safety:
	poetry check
	poetry run safety check --full-report
	poetry run bandit -ll --recursive cleaning_utils tests

.PHONY: lint
lint: test check-codestyle mypy check-safety

#* Docker
# Example: make docker VERSION=latest
# Example: make docker IMAGE=some_name VERSION=0.1.0
.PHONY: docker-build
docker-build:
	@echo Building docker $(IMAGE):$(VERSION) ...
	docker build \
		-t $(IMAGE):$(VERSION) . \
		-f ./docker/Dockerfile --no-cache

# Example: make clean_docker VERSION=latest
# Example: make clean_docker IMAGE=some_name VERSION=0.1.0
.PHONY: docker-remove
docker-remove:
	@echo Removing docker $(IMAGE):$(VERSION) ...
	docker rmi -f $(IMAGE):$(VERSION)

#* Cleaning
.PHONY: pycache-remove
pycache-remove:
	find . | grep -E "(__pycache__|\.pyc|\.pyo$$)" | xargs rm -rf

.PHONY: build-remove
build-remove:
	rm -rf build/

.PHONY: clean-all
clean-all: pycache-remove build-remove docker-remove


.PHONY: change-codestyle
change-codestyle:
	poetry run isort --settings-path pyproject.toml ./
	poetry run black --config pyproject.toml ./