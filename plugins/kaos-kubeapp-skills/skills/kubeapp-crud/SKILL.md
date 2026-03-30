---
name: kubeapp-crud
description: "Full lifecycle management of KubeApps on the KAOS platform — create, read, update, delete, and deep-verify. Use this skill whenever the user wants to create a new KubeApp, deploy an application, check KubeApp status, modify KubeApp configuration, delete a KubeApp, or verify that all provisioned resources (CI pipeline, registry, deployment, ConfigMap, ingress) are healthy. Also use when the user mentions 'kubeapp', 'deploy an app', 'create application', 'ship to dev', 'application status', or wants to manage any application lifecycle on KAOS."
---

# KubeApp CRUD — Full Lifecycle Management

Manage the complete lifecycle of a KubeApp on the KAOS platform: create, read, update, delete, and verify all provisioned resources end-to-end.

## When to Use

- User wants to create a new application
- User wants to check application status or health
- User wants to update application configuration (profile, env vars, environments, visibility)
- User wants to delete an application
- User wants to verify all CI/CD infrastructure, registry auth, and deployment resources

## Prerequisites

Before any KubeApp operation, you need:
- A **KubeProject** in Ready state (the project this app belongs to)
- A **KubeAppTemplate** (defines the application type — python-rest-api, go-rest-api, react-frontend)
- Access to the control plane cluster (`KUBECONFIG` set)

Discover these first:
```bash
kubectl get kubeproject -A          # Find available projects
kubectl get xkubeapptemplate        # Find available templates
```

---

## CREATE — Provision a New KubeApp

### Step 1: Gather Information

Ask the user (or determine from context):
1. **App name** — lowercase, alphanumeric + hyphens (e.g., `my-backend`)
2. **Project** — which KubeProject (e.g., `wow-xmas`)
3. **Template** — which KubeAppTemplate (e.g., `python-rest-api`)
4. **Profile** — resource size: `small` (default), `medium`, `large`
5. **Visibility** — `private` (default), `public`, `internal`
6. **Target environments** — which environment types to deploy to (e.g., `dev`, `stage`)
7. **Environment variables** — any custom env vars (global or per-environment)

### Step 2: Determine the Namespace

KubeApps live in the **KubeOrg namespace** (not the project namespace). Find it:
```bash
kubectl get kubeproject <project-name> -A -o jsonpath='{.spec.kubeOrgRef}'
```
The KubeApp is created in the namespace matching the KubeOrg name (typically the org namespace like `kaos-test`).

### Step 3: Apply the KubeApp

```yaml
apiVersion: schema.kubecore.io/v1beta1
kind: KubeApp
metadata:
  name: <app-name>
  namespace: <org-namespace>
spec:
  displayName: "<Human Readable Name>"
  description: "<What this application does>"
  kubeProjectRef: "<project-name>"
  kubeAppTemplateRef: "<template-name>"
  profile: "small"
  visibility: "public"
  environmentSelector:
    environmentTypes:
      - "dev"
  # Optional: environment variables
  k8sAppConfig:
    environmentVariables:
      global:
        CUSTOM_VAR: "value"
      dev:
        LOG_LEVEL: "debug"
```

The `environmentSelector` is critical — without it, the app will NOT deploy to any environment. Always set it.

### Step 4: Monitor Provisioning

Watch the phase progression: `Reconciling → Syncing → Reporting → Ready`

```bash
kubectl get kubeapp <app-name> -n <org-ns> --watch
```

Typical time to Ready: **3-5 minutes**.

If stuck in a phase for more than 5 minutes, check conditions:
```bash
kubectl describe kubeapp <app-name> -n <org-ns>
```

### Step 5: Verify (see VERIFY section below)

Once Ready, run the full verification checklist.

---

## READ — Check KubeApp Status

### Quick Status
```bash
kubectl get kubeapp <app-name> -n <org-ns> -o wide
```

Expected output when healthy:
```
NAME       PHASE   PROJECT    TEMPLATE          PROFILE   REPOSITORY                                    READY   AGE
my-app     Ready   my-proj    python-rest-api   small     https://github.com/org/proj-my-app            true    5m
```

### Detailed Status
```bash
kubectl get kubeapp <app-name> -n <org-ns> -o yaml
```

Key fields to check:
- `status.phase` — should be `Ready`
- `status.repositoryUrl` — GitHub repository URL
- `status.selectedEnvironments` — which environments are active
- `status.conditions` — look for `type: Ready, status: "True"`

### Child Resources
```bash
kubectl get xgithubapp,xk8sapp -n <org-ns> | grep <app-name>
```

Both should show `SYNCED=True, READY=True`.

---

## UPDATE — Modify KubeApp Configuration

### Update Profile
```bash
kubectl patch kubeapp <app-name> -n <org-ns> --type=merge -p '{"spec":{"profile":"medium"}}'
```

### Update Environment Variables
```bash
kubectl patch kubeapp <app-name> -n <org-ns> --type=merge -p '{
  "spec": {
    "k8sAppConfig": {
      "environmentVariables": {
        "global": {"NEW_VAR": "value"},
        "dev": {"LOG_LEVEL": "debug"}
      }
    }
  }
}'
```

### Add/Change Target Environments
```bash
kubectl patch kubeapp <app-name> -n <org-ns> --type=merge -p '{
  "spec": {
    "environmentSelector": {
      "environmentTypes": ["dev", "stage"]
    }
  }
}'
```

### Update Visibility
```bash
kubectl patch kubeapp <app-name> -n <org-ns> --type=merge -p '{"spec":{"visibility":"public"}}'
```

After any update, the operator detects the spec change (generation mismatch) and re-reconciles automatically. Monitor with:
```bash
kubectl get kubeapp <app-name> -n <org-ns> --watch
```

---

## DELETE — Remove a KubeApp

### Delete the KubeApp
```bash
kubectl delete kubeapp <app-name> -n <org-ns>
```

### Monitor Deletion

The operator deletes resources sequentially: XK8sApp first, then XGitHubApp. This takes 1-3 minutes.

```bash
kubectl get kubeapp <app-name> -n <org-ns> --watch
```

### Verify Cleanup
```bash
# Child XRs should be gone
kubectl get xgithubapp,xk8sapp -n <org-ns> | grep <app-name>

# Crossplane Objects should be gone
kubectl get object.kubernetes.m.crossplane.io -n <org-ns> | grep <app-name>
```

If deletion hangs, check the operator logs:
```bash
kubectl logs -n kubecore-system deployment/kubecore-operator-controller-manager --tail=100 | grep <app-name>
```

---

## VERIFY — Deep Resource Verification

After creation or when troubleshooting, verify all provisioned resources across both the control plane and child cluster.

### Control Plane Verification

```bash
# 1. KubeApp status
kubectl get kubeapp <app-name> -n <org-ns> -o wide

# 2. Child XRs (both should be Synced + Ready)
kubectl get xgithubapp <app-name> -n <org-ns>
kubectl get xk8sapp <app-name> -n <org-ns>

# 3. All Crossplane Objects (count and health)
kubectl get object.kubernetes.m.crossplane.io -n <org-ns> | grep <app-name>
# All should show Synced=True, Ready=True

# 4. GitHub webhook
kubectl get repositorywebhook.repo.github.m.upbound.io -n <org-ns> | grep <app-name>
```

### Child Cluster Verification

You need the child cluster kubeconfig. See `references/child-cluster-access.md` for how to obtain it.

```bash
# 5. CI namespace resources (EventSource, Sensor, Ingress)
kubectl get eventsource,sensor -n <project>-ci | grep <app-name>
kubectl get ingress -n <project>-ci | grep <app-name>
# EventSource: Deployed=True, Sensor: all conditions True

# 6. CI pods (should be Running, 0 restarts)
kubectl get pods -n <project>-ci | grep <app-name>

# 7. TLS certificate (should be Ready)
kubectl get certificate -n <project>-ci | grep <app-name>

# 8. ESO registry auth (CI push secret)
kubectl get externalsecret -n <project>-ci | grep <app-name>.*registry
kubectl get secret ci-registry-auth -n <project>-ci

# 9. Pull secret in environment namespace
kubectl get secret <project>-registry-pull -n <project>-<env> -o jsonpath='{.type}'
# Should be: kubernetes.io/dockerconfigjson

# 10. Deployment and pod
kubectl get deployment <project>-<app-name> -n <project>-<env>
kubectl get pods -n <project>-<env> -l app=<project>-<app-name>

# 11. ConfigMap with env vars
kubectl get configmap <project>-<app-name>-config -n <project>-<env> -o jsonpath='{.data}'

# 12. Service
kubectl get svc <project>-<app-name>-svc -n <project>-<env>

# 13. imagePullSecrets on Deployment
kubectl get deployment <project>-<app-name> -n <project>-<env> -o jsonpath='{.spec.template.spec.imagePullSecrets}'
```

### Verification Summary Template

After running all checks, report status in this format:

```
## KubeApp Verification: <app-name>

| Resource | Location | Status |
|----------|----------|--------|
| KubeApp | control plane | Ready / Phase |
| XGitHubApp | control plane | Synced+Ready / error |
| XK8sApp | control plane | Synced+Ready / error |
| Crossplane Objects | control plane | N/N healthy |
| GitHub Webhook | control plane | Synced+Ready / error |
| EventSource | child:<project>-ci | Deployed / error |
| Sensor | child:<project>-ci | Deployed / error |
| Ingress + TLS | child:<project>-ci | Active + valid cert / error |
| CI Registry Auth | child:<project>-ci | SecretSynced / error |
| Pull Secret | child:<project>-<env> | dockerconfigjson / missing |
| Deployment | child:<project>-<env> | Ready N/N / error |
| Pod | child:<project>-<env> | Running / status |
| ConfigMap | child:<project>-<env> | N keys / missing |
| Service | child:<project>-<env> | ClusterIP:port / missing |
| imagePullSecrets | child:<project>-<env> | configured / missing |
```

---

## Troubleshooting

### KubeApp stuck in Reconciling
- Check KubeProject is Ready: `kubectl get kubeproject <project> -A`
- Check KubeAppTemplate exists: `kubectl get xkubeapptemplate <template>`
- Check operator logs: `kubectl logs -n kubecore-system deployment/kubecore-operator-controller-manager --tail=100`

### KubeApp stuck in Syncing
- XGitHubApp or XK8sApp not ready
- Check: `kubectl describe xgithubapp <app> -n <org-ns>`
- Common: branch protection rules failing, GitHub API rate limits

### Pod ImagePullBackOff
- Pull secret missing or invalid
- Check: `kubectl get secret <project>-registry-pull -n <project>-<env>`
- Check: `kubectl get deployment <project>-<app> -n <project>-<env> -o jsonpath='{.spec.template.spec.imagePullSecrets}'`

### Pod CreateContainerConfigError
- ConfigMap or Secret missing
- Check: `kubectl get configmap <project>-<app>-config -n <project>-<env>`

### CI Workflow not triggering
- Check EventSource logs: `kubectl logs -n <project>-ci -l eventsource-name=<app>`
- Check Sensor logs: `kubectl logs -n <project>-ci -l sensor-name=<app>`
- Check webhook delivery on GitHub: repository Settings → Webhooks → Recent Deliveries

### Deletion hangs
- Check operator logs for deletion errors
- XK8sApp must delete before XGitHubApp (sequential)
- If stuck, check for finalizers: `kubectl get xk8sapp <app> -n <org-ns> -o jsonpath='{.metadata.finalizers}'`

---

## Environment Variables Merge Chain

When creating or updating a KubeApp, environment variables follow this merge order (lowest to highest priority):

1. **Template environmentSchema defaults** — `SERVICE_NAME`, `LOG_LEVEL`, etc. with context-derived values
2. **Global environmentVariables** — `spec.k8sAppConfig.environmentVariables.global`
3. **Per-environmentType overrides** — `spec.k8sAppConfig.environmentVariables.dev` / `.stage` / `.prod`

The base ConfigMap gets template + global. Each environment overlay gets the fully merged set.

---

## Reference Files

- `references/child-cluster-access.md` — How to obtain child cluster kubeconfig
- `references/kubeapp-spec.md` — Full KubeApp CRD field reference
