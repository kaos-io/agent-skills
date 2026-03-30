# KubeApp CRD Field Reference

## API
- **apiVersion:** `schema.kubecore.io/v1beta1`
- **kind:** `KubeApp`
- **scope:** Namespaced (in KubeOrg namespace)

## Spec Fields

### Required
| Field | Type | Description |
|-------|------|-------------|
| `displayName` | string | Human-readable name |
| `description` | string | Application description |
| `kubeProjectRef` | string | Parent KubeProject name |
| `kubeAppTemplateRef` | string | XKubeAppTemplate name |

### Optional
| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `profile` | string | `"small"` | Resource profile: small, medium, large |
| `visibility` | string | `"private"` | Repository visibility: private, public, internal |
| `environmentSelector` | object | none (no deploy) | Controls which environments to deploy to |
| `features` | object | all enabled | Toggle repository, teams, ciCd, webhooks |
| `k8sAppConfig` | object | nil | Health check, base resources, env vars, ingress, autoscaling |
| `gitOpsConfig` | object | defaults | basePath, branchName, autoMerge per env |
| `sdlcConfig` | object | promotions enabled | SDLC settings |
| `connections` | []object | nil | Dependencies on other KubeApps (PRD-CONN-001) |

### Environment Selector
```yaml
environmentSelector:
  environmentTypes: ["dev"]        # By type (dev/stage/prod)
  names: ["dev", "staging-us"]     # By exact name (takes precedence)
  matchLabels: {team: "backend"}   # By labels (AND logic)
  exclude: ["dev-experimental"]    # Exclude (applied last)
```

### K8sAppConfig
```yaml
k8sAppConfig:
  healthCheck:
    path: "/healthz"
    initialDelaySeconds: 15
    periodSeconds: 10
  baseResources:
    serviceAccount: {enabled: true, name: "custom-sa"}
    configMap: {enabled: true, data: {KEY: "value"}}
    secret: {enabled: true, type: "Opaque"}
  environmentVariables:
    global: {LOG_LEVEL: "info"}
    dev: {LOG_LEVEL: "debug", DEBUG_MODE: "true"}
  ingressConfig:
    enabled: true
    pathType: "Prefix"
  autoscalingConfig:
    enabled: {dev: false, prod: true}
```

## Status Fields

| Field | Type | Description |
|-------|------|-------------|
| `phase` | string | Reconciling, Syncing, Reporting, Ready, Failed, Deleting |
| `conditions` | []Condition | Ready, ValidationFailed, ResourcesCreated, etc. |
| `repositoryUrl` | string | Created GitHub repository URL |
| `selectedEnvironments` | []string | Active environment names |
| `xGitHubAppRef` | ResourceRef | Reference to XGitHubApp XR |
| `xK8sAppRef` | ResourceRef | Reference to XK8sApp XR |
| `connections` | []ResolvedConnection | Resolved dependency graph (PRD-CONN-001) |

## Available Templates

| Template | Type | Language | Port | Components |
|----------|------|----------|------|------------|
| python-rest-api | rest | python | 8000 | deployment, rollout, service, ingress |
| go-rest-api | rest | go | 8080 | deployment, service, ingress |
| react-frontend | frontend | javascript | 80 | deployment, service, ingress |

## Resource Naming Convention

| Resource | Name Pattern | Namespace |
|----------|-------------|-----------|
| KubeApp | `{app-name}` | KubeOrg namespace |
| XGitHubApp | `{app-name}` | KubeOrg namespace |
| XK8sApp | `{app-name}` | KubeOrg namespace |
| GitHub Repository | `{project}-{app-name}` | GitHub org |
| Deployment | `{project}-{app-name}` | `{project}-{env}` |
| Service | `{project}-{app-name}-svc` | `{project}-{env}` |
| ConfigMap | `{project}-{app-name}-config` | `{project}-{env}` |
| Ingress | `{project}-{app-name}-ingress` | `{project}-{env}` |
| EventSource | `{app-name}` | `{project}-ci` |
| Sensor | `{app-name}` | `{project}-ci` |
| CI Ingress | `{app-name}-ci-webhook` | `{project}-ci` |
