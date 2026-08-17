# Installing Pinniped w/ Helm
Pinniped requires namespaces to be created manually prior to installing either the supervisor or concierge

## Namespaces
The chart doesn't create its own namespace - create it (under whatever name you like, it
doesn't have to be `pinniped-concierge`) before installing:
```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: pinniped-concierge
  labels:
    app: pinniped-concierge
    pod-security.kubernetes.io/enforce: privileged
```

The `pod-security.kubernetes.io/enforce: privileged` label is required - the
kube-cert-agent Pod the concierge creates needs privileged Pod Security Admission. If you
install into a namespace that's missing this label, `helm install`/`helm upgrade` fails
fast with a clear error instead of the namespace silently rejecting the concierge's Pods
later. This check needs live cluster access (it uses Helm's `lookup`), so it's skipped
under `helm template`/`--dry-run=client`.

## Installation

#### Installing the Concierge
```bash
helm install pinniped-concierge pinniped-concierge-chart --namespace pinniped-concierge --atomic --values <your-values.yaml>
```

`values.schema.json` validates the values you pass in; `helm lint`/`helm install`/`helm template`
will fail with a clear message if a required field is missing.

At minimum you'll need to set, per cluster:
```yaml
certificate:
  hostname: ""       # DNS name for the cert-manager Certificate (or disable: certificate.enabled: false)
  clusterIssuer: ""
  secretName: ""

jwtAuthenticators:
  - name: supervisor-jwt-authenticator
    issuer: ""        # the Supervisor's issuer URL
    audience: ""       # openssl rand -base64 32
    claims:
      username: ""
      groups: ""
    tls:
      certificateAuthorityDataSource:
        kind: Secret
        name: ""        # should match certificate.secretName above
        key: ca.crt
```

## Configuration

See `values.yaml` for the full set of configurable fields and their defaults. Highlights:

| Key | Purpose |
| --- | --- |
| `image.repository` / `.tag` / `.digest` / `.pullPolicy` | Concierge image. `tag` defaults to `v<appVersion>` from `Chart.yaml`; `digest` defaults to the digest from Pinniped's official install manifest for that `appVersion` (clear it if you override `tag` independently). |
| `replicaCount`, `resources`, `nodeSelector`, `tolerations`, `affinity`, `priorityClassName` | Standard Deployment scheduling/sizing knobs. |
| `extraEnv`, `extraVolumes`, `extraVolumeMounts` | Extend the concierge container without forking the chart. |
| `service.api.*`, `service.proxy.*` | Type/annotations for the two concierge Services. |
| `credentialIssuer.impersonationProxy.*` | Impersonation proxy mode and its Service type/annotations. |
| `config.*` | Structured `pinniped.yaml` operator config (discovery URL, serving cert lifetimes, TLS ciphers, audit mode, kube-cert-agent image/prefix). Rendered via the `pinniped-concierge-config` ConfigMap. |
| `certificate.enabled` | Toggle the cert-manager `Certificate` this chart creates for the JWTAuthenticator CA bundle. Disable if you manage that Secret another way. |
| `jwtAuthenticators` / `webhookAuthenticators` | Lists - add as many identity provider authenticators as you need. `jwtAuthenticators[].claims.usernameExpression`/`.groupsExpression`/`.extra` and `.claimValidationRules`/`.userValidationRules` cover the CRD's advanced CEL-based fields. |
| `podDisruptionBudget.enabled` | Off by default; enable for multi-replica HA. |
| `extraManifests` | Arbitrary additional objects (e.g. a `NetworkPolicy`, an `ExternalSecret`), templated with `tpl` so they can reference `.Values`/`.Release`/`.Chart`. |
| `nameOverride` / `fullnameOverride` | Rename chart-created resources. Leave unset for existing installs - the default reproduces today's `pinniped-concierge-*` names exactly when the release is named `pinniped-concierge`. |

Every value above has a safe, unchanged-behavior default except `certificate.*` and
`jwtAuthenticators[0].*`, which are unset and validated with Helm's `required` function - the
chart will refuse to render until you supply them

### Migrating from chart 0.1.x

`values.yaml` was restructured in `0.2.0` for configurability. Notable renames:

- `supervisor.*` -> `jwtAuthenticators[0].*` (now a list; `supervisor.issuer` -> `jwtAuthenticators[0].issuer`, etc.)
- `certificate.*` field names are unchanged, but the resource is now gated by `certificate.enabled` (default `true`, so existing values files keep working unmodified).
- The chart previously pinned `ghcr.io/vmware/pinniped/pinniped-server:v0.45.0` regardless of `Chart.yaml`'s `appVersion` (which had already been bumped to `0.47.0`). The image now always tracks `appVersion` unless you set `image.tag`/`image.digest`.

## RBAC
Kubernetes RBAC policies are *not* controlled by these charts. Recommended to use RBAC Manager to configure these.
