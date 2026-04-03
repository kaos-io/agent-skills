# KAOS Debug Patterns — Known Platform Quirks

Reference document for the `/kaos-debug` skill. These are verified platform behaviors that should be consulted before diagnosing issues.

---

## Status Endpoint Quirks

### Delete Status False-Failure

`mcp__KAOS__status` returns `INTERNAL_ERROR` with `complete=true, failed=true` when a DELETE operation completes and the resource is already gone. This happens because the status endpoint tries to look up the transaction for the now-deleted resource and fails.

**This is NOT a real failure.** Verification pattern:
```
kaos:status(...)  → INTERNAL_ERROR (complete=true, failed=true)
kaos:list(...)    → resource absent → deletion SUCCEEDED
```

Always follow a delete status check with `kaos:list()` to confirm the resource is actually gone.

### 95% Stall Pattern

Delete status commonly holds at 95% completion for 1-2 polling cycles before jumping to 100%. This is normal — do not interpret it as a stuck operation.

---

## Provisioning Timings (novelcore org, verified)

These timings are approximate and depend on cloud provider responsiveness:

| Resource | Operation | Typical Duration |
|----------|-----------|-----------------|
| KubeProject (2 environments) | Create | ~7 minutes |
| KubeApp (python-rest-api, small) | Create | ~7-8 minutes |
| KubeApp | Delete | ~9 minutes (ArgoCD sync is slow) |
| KubeProject | Delete | ~5 minutes |

If a resource takes significantly longer than these benchmarks, it may genuinely be stuck.

---

## Common Root Causes by Symptom

### "Composition not in runtime"
1. Check if the XRD definition was applied: `kubectl get xrd`
2. Check if the composition was applied: `kubectl get composition`
3. Verify `compositeTypeRef` matches between composition and XRD
4. Check Crossplane provider health: `kubectl get providers`

### "Resource stuck in Reconciling/Syncing"
1. Check if child XRs are healthy: `kubectl get <xr-type> -o yaml`
2. Look for ProviderConfig issues: `kubectl get providerconfig`
3. Check if RBAC allows the operation: `kubectl auth can-i`
4. Review operator logs for the specific controller

### "Finalizer preventing deletion"
1. Identify which finalizer is stuck: `kubectl get <resource> -o jsonpath='{.metadata.finalizers}'`
2. Check if the finalizer controller is running
3. For `kubecore.io/wait-for-kubesystem`: child resources must be deleted first
4. Emergency scripts available at: `scripts/emergency-fix-stuck-kubepool.sh`

### "Secret/credential not reaching target"
1. Check ExternalSecret/ClusterSecretStore health
2. Verify PushSecret configuration
3. Check if the secret exists in the source (AWS Secrets Manager)
4. Verify IAM roles and IRSA configuration

### "ArgoCD application not syncing"
1. Check if the ArgoCD Application resource exists in the child cluster
2. Verify the git repository URL and branch
3. Check ArgoCD server logs for sync errors
4. Verify OIDC SSO configuration if login-related

---

## CI/CD Pipeline Names (stable, repo-specific)

| Pipeline | Trigger | Name |
|----------|---------|------|
| Dev release | PR merge to dev | "Release to dev environment" |
| RC creation | Manual dispatch from dev | "Craft RC, release dev to stage" |
| RC release | Auto on RC branch PR open | "RC release, deploy to stage" |
| Dev dispatch job | Post-merge | `notify-gitops-repository` |
| Stage dispatch | Event type | `staging-environment-update` |

---

## Branch Protection on Dev

- Required checks: `validate-pr`, `build-scan-push`, `gate-check` + 1 approving review
- `build-scan-push` is marked required but shows `skipping` on unlabeled PRs (only runs with `deploy-preview` label)
- `enforce_admins=false` — use `gh pr merge --admin` for e2e test merges
