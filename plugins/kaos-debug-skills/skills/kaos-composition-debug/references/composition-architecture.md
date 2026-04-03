# KAOS Composition Architecture Reference

Reference document for the `/kaos-composition-debug` skill. Documents the Crossplane composition hierarchy and router pattern used by the KAOS platform.

---

## Resource Hierarchy and XR Mapping

```
KubeOrg (Organization) — cloud-agnostic phases, OrgCompositionRouter dispatch
├── XAWSProvider ({org}-awsprovider)
├── XGithubProvider ({org}-githubprovider)
├── XAwsNetwork ({org}-{region}-network)
└── GitHub Secret ({org}-github-credentials)

KubePool (Cluster) — cloud-agnostic phases, CompositionRouter dispatch
├── XEKS ({pool}-eks)
└── XKubeSystem ({pool}-system)
    ├── Release/argocd
    ├── Release/external-dns
    ├── Release/cert-manager
    ├── Release/external-secrets
    └── Release/... (platform tools)

KubeProject (Project)
├── XGitHubProject ({project}-github)
└── XKubEnv ({project}-{env}-kubenv)

KubeApp (Application)
├── XGitHubApp ({app}-github)
└── XK8sApp ({app}-k8s)
```

---

## Composition Directory Structure

All compositions live in `compositions/apis/`:

```
compositions/apis/
├── kubeorg/
│   ├── awsprovider/        # XAWSProvider composition
│   │   ├── definition.yaml
│   │   ├── composition.yaml
│   │   └── tests/
│   ├── githubprovider/     # XGithubProvider composition
│   ├── network/            # XAwsNetwork composition
│   └── ...
├── kubepool/
│   ├── aws/
│   │   └── eks/            # XEKS composition
│   │       ├── definition.yaml
│   │       ├── composition.yaml
│   │       └── tests/
│   └── system/             # XKubeSystem composition
│       ├── definition.yaml
│       ├── composition.yaml
│       └── tests/
├── kubeproject/
│   ├── githubproject/      # XGitHubProject composition
│   └── kubenv/             # XKubEnv composition
└── kubeapp/
    ├── githubapp/          # XGitHubApp composition
    └── k8sapp/             # XK8sApp composition
```

---

## Composition Router Pattern

The operator uses composition routers to decouple cloud-specific logic from phase execution:

### KubePool Router
```go
// framework.CompositionRouter → CompositionSetContract
router["aws"] = NewAWSCompositionSet()
// Adding GCP: router["gcp"] = NewGCPCompositionSet()
```

### KubeOrg Router
```go
// framework.OrgCompositionRouter → OrgCompositionSetContract (4 methods)
orgRouter["aws"] = NewAWSOrgCompositionSet()
// Methods: SyncResources, ExtractStatus, CheckHealthy, HandleDeletion
```

---

## Key Conventions

- **Namespacing:** XRs are namespaced in the org namespace (CON-12)
- **Parameters:** All composition input via `spec.parameters` (CON-13), no EnvironmentConfig
- **Naming:** XR names follow `{resource-name}-{suffix}` pattern
- **Labels:** All composed resources carry `platform.kubecore.io/` labels for hierarchy tracking
- **ProviderConfig:** Each org has its own ProviderConfig (`{org}-kubernetes`, `{org}-aws`, etc.)

---

## Common Composition Issues by Layer

### Definition (XRD) Layer
- Missing field in OpenAPI schema → patch fromFieldPath fails silently
- Wrong API version → claims can't be created
- Missing `status.subresources` → status never propagates

### Composition Layer
- `compositeTypeRef` mismatch with XRD → composition never matches
- Patch `fromFieldPath` referencing non-existent field → null values in composed resources
- Missing `connectionDetails` → secrets not propagated
- Wrong `base` manifest apiVersion → Crossplane can't create the resource

### Provider Layer
- Provider not installed → composed resources stuck as Pending
- ProviderConfig not found → resources fail with "referenced ProviderConfig not found"
- IRSA role missing permissions → cloud resources fail to create
- Provider revision mismatch → API version incompatibility
