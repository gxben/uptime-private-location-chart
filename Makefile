# Copyright 2026 Benjamin Zores
# Apache License, Version 2.0 (see LICENSE or https://www.apache.org/licenses/LICENSE-2.0.txt)
# SPDX-License-Identifier: Apache-2.0

CHART_DIR = charts/uptime-private-location
CHART     = uptime-private-location
VERSION   = $(shell git describe --tags --always --dirty 2>/dev/null | sed 's/^v//' || echo 0.0.0-dev)
OCI_REPO  = oci://ghcr.io/gxben/charts

V = 0
Q = $(if $(filter 1,$V),,@)
M = $(shell printf "\033[34;1m▶\033[0m")

.PHONY: all
all: lint template package ; @ ## Run all checks then package the chart
	$Q echo "done"

# ── Lint & validate ────────────────────────────────────────────────────────────

.PHONY: lint
lint: ; $(info $(M) linting chart…) @ ## Run helm lint against the chart
	$Q helm lint $(CHART_DIR)

.PHONY: template
template: ; $(info $(M) rendering chart templates…) @ ## Render templates with default values
	$Q helm template $(CHART) $(CHART_DIR) > /dev/null
	$Q helm template $(CHART) $(CHART_DIR) --set kind=StatefulSet --set persistence.enabled=true --set service.enabled=true > /dev/null

.PHONY: docs
docs: ; $(info $(M) checking README values table…) @ ## Regenerate README values table with helm-docs (if installed)
	$Q command -v helm-docs >/dev/null 2>&1 && helm-docs --chart-search-root=charts || echo "helm-docs not installed, skipping"

# ── Package & install ──────────────────────────────────────────────────────────

.PHONY: package
package: ; $(info $(M) packaging chart $(VERSION)…) @ ## Package the chart as a .tgz
	$Q helm package $(CHART_DIR) --version $(VERSION) --app-version $(VERSION)

.PHONY: install
install: ; $(info $(M) dry-run installing chart…) @ ## Dry-run install with default values
	$Q helm install $(CHART) $(CHART_DIR) --dry-run --debug

# ── Housekeeping ────────────────────────────────────────────────────────────────

.PHONY: clean
clean: ; $(info $(M) cleaning…) @ ## Remove generated artefacts
	$Q rm -f *.tgz

.PHONY: help
help: ## Display this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'
