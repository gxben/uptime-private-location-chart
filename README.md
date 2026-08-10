# uptime-private-location-chart

A Helm chart for the [Uptime.com Private Location](https://github.com/uptime-com/uptime-private-location)
probe server.

This repository is **chart-only**. The probe itself and its container image
are built and published upstream by Uptime.com
(`uptimecom/uptime-private-location` on Docker Hub) — nothing here rebuilds
or repackages that code. This chart just wraps the upstream
[`k8s-sample.yaml`](https://github.com/uptime-com/uptime-private-location/blob/latest/k8s-sample.yaml)
so it can be deployed and managed with Helm.

This is **not** an official Uptime.com chart.

---

## Installation

The chart is published to GHCR as an OCI artifact.

```bash
helm install my-probe \
  oci://ghcr.io/gxben/charts/uptime-private-location \
  --set apiToken.value=YOUR_UPTIME_API_TOKEN
```

Or with a values file:

```yaml
# values.my-probe.yaml
apiToken:
  value: "ut_xxxxxxxxxxxxxxxxxxxxxxxx"
image:
  tag: "5.4"
config:
  availableCpuCores: "2"
  txnLimitBrowsers: "1"
resources:
  requests: { cpu: "1.0", memory: "2Gi" }
  limits:   { cpu: "2.0", memory: "4Gi" }
```

```bash
helm install my-probe oci://ghcr.io/gxben/charts/uptime-private-location -f values.my-probe.yaml
```

## API token

The chart expects exactly one of:

- `apiToken.value` — inline; the chart creates a plain Kubernetes `Secret`.
- `apiToken.secretName` (+ `apiToken.secretKey`) — reference a Secret you
  manage yourself (e.g. created out-of-band, via SOPS, or by your own
  secrets tooling).

Don't put real tokens in committed values files.

## Multiple probes

Each Uptime.com Private Location probe is identified by its API token, so
**one token = one probe**. To run several, install this chart multiple
times with different release names, each with its own token:

```bash
helm install probe-eu oci://ghcr.io/gxben/charts/uptime-private-location -f probe-eu.yaml
helm install probe-us oci://ghcr.io/gxben/charts/uptime-private-location -f probe-us.yaml
```

Don't try to scale `replicaCount` past 1 with a single token — only one of
the pods will register correctly with Uptime.com.

## Persistence

The upstream sample uses in-memory `emptyDir` volumes for `/dev/shm` and
`/home/uptime/run` — the chart matches that by default. If you also want
durable storage for nagios state, uptime var, and logs, set
`persistence.enabled=true`. With `kind: Deployment` the chart creates PVCs;
with `kind: StatefulSet` it uses `volumeClaimTemplates`.

Note: the upstream README does not require persistence for the probe to
function, since state is reconstructed from the configuration packet pushed
by Uptime.com.

## Healthchecks

Liveness/readiness probes are **disabled by default**. The upstream README
explicitly says the old `/status` endpoint is gone in 3.x+ and recommends
Heartbeat checks from Uptime.com itself for monitoring whether the probe is
healthy. Enable the TCP probes here only if you understand the tradeoff.

## Values reference

See [`charts/uptime-private-location/values.yaml`](charts/uptime-private-location/values.yaml)
for the full list. Keys you will likely touch:

| Key | Default | Notes |
| --- | --- | --- |
| `replicaCount` | `1` | One token per replica — usually keep at 1 |
| `image.tag` | `"5.4"` | Pin this; don't ride `latest` in production |
| `apiToken.value` | `""` | Required if not using `apiToken.secretName` |
| `apiToken.secretName` | `""` | Reference your own Secret instead |
| `kind` | `Deployment` | `Deployment` \| `StatefulSet` |
| `config.availableCpuCores` | `"2"` | Should match `resources.limits.cpu` |
| `config.txnLimitBrowsers` | `"1"` | ~3 per CPU core max |
| `resources` | 1–2 CPU / 2–4Gi | Upstream minimum for Chromium checks |
| `ramdisk.sizeLimit` | `2Gi` | `/dev/shm` for Chromium |
| `persistence.enabled` | `false` | Switch on for PVCs |
| `service.enabled` | `false` | Only needed if you want to reach the Nagios UI on 8443 |

## What this chart deliberately does NOT do

- It does not build, fork, or repackage the probe image — that's upstream's
  job (`uptime-com/uptime-private-location`).
- It does not configure HPA. Scaling these pods is not the same as scaling
  a stateless web service — a new pod needs a new token.
- It does not set up an Ingress for 8443. The Nagios UI is for debugging
  and shouldn't be exposed publicly.
- It does not manage the API token contents itself. Bring your own secret
  manager if you don't want `apiToken.value` in a values file.

---

## Development

### Pre-commit hooks

```bash
pip install pre-commit
pre-commit install --hook-type pre-commit --hook-type commit-msg
```

Hooks enforce Conventional Commits format and run `helm lint` and basic
YAML hygiene checks before every commit.

### Commit convention

This project uses [Conventional Commits](https://www.conventionalcommits.org/):

| Type | Release |
| --- | --- |
| `feat` | minor |
| `fix`, `perf`, `refactor`, `revert` | patch |
| `BREAKING CHANGE` footer or `!` suffix | major |
| `docs`, `chore`, `style`, `test`, `ci` | none |

### Make targets

```bash
make lint      # helm lint
make template  # render templates with default + alternate values
make package   # package the chart as a .tgz
make install   # dry-run install with default values
make docs      # regenerate README values table with helm-docs, if installed
make clean     # remove *.tgz
```

### CI/CD

| Workflow | Trigger | Purpose |
| --- | --- | --- |
| `ci.yml` | push / PR to `main` | `ct lint`, template rendering, `kubeconform` schema validation |
| `sec.yml` | push / PR to `main` | Trivy config scan of the chart templates |
| `release.yml` | manual `workflow_dispatch` | semantic-release → GitHub Release → publish chart to GHCR (OCI) → ArtifactHub metadata |

Trigger a release by running the `release.yml` workflow manually. It
determines the next version from conventional commits, updates
`CHANGELOG.md`, creates a GitHub Release, and publishes the chart as an OCI
artifact to `ghcr.io/gxben/charts/uptime-private-location`.

> **Note**: set `RELEASE_TOKEN` in repository secrets (PAT with
> `contents: write`) so semantic-release can push the CHANGELOG commit back
> to `main` when branch protection is enabled.

## License

Apache License 2.0 — see [LICENSE](LICENSE).
Copyright 2026 Benjamin Zores.
