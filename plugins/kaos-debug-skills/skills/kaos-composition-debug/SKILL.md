---
name: kaos-composition-debug
description: Crossplane composition-specific debugging. Validates composition-XRD alignment, traces patch chains, checks runtime providers, compares rendered vs expected manifests, and verifies RBAC and ProviderConfig.
user-invocable: true
---

# KAOS Composition Debug

Systematic debugging workflow for Crossplane compositions and XRDs on the KAOS platform. Walks through every layer where composition issues can occur: definition alignment, provider health, patch chain integrity, rendered resource accuracy, and RBAC/ProviderConfig validity.

**Follow the steps in order. Do not skip steps — composition issues often have multiple contributing causes.**

## Usage

```
/kaos-composition-debug
/kaos-composition-debug [composition-name or xrd-name]
/kaos-composition-debug [xr-type/xr-name]
```

## Process

---

### Step 1: Identify Target

Determine which composition/XRD to investigate.

**If the user named a specific resource:** use it directly.

**If not — detect from context:**
1. Check for recent errors in operator logs mentioning composition issues
2. Look for XRs in non-Ready state: `kubectl get composite -A`
3. Ask the user which composition or XR is problematic

**Gather baseline data:**
```bash
kubectl get xrd                    # All XRD definitions
kubectl get composition            # All compositions
kubectl get composite -A           # All composite resources (XRs)
```

Identify the specific:
- **XRD** (CompositeResourceDefinition)
- **Composition** (that targets the XRD)
- **XR** (live composite resource instance, if one exists)

---

### Step 2: Validate Composition ↔ XRD Alignment

Get both resources and compare:

```bash
kubectl get xrd <xrd-name> -o yaml
kubectl get composition <composition-name> -o yaml
```

**Check these alignment points:**

| Check | How | Common Failure |
|-------|-----|----------------|
| `compositeTypeRef` matches | Composition `spec.compositeTypeRef.apiVersion` and `kind` must match XRD's `spec.group` + `spec.names.kind` | Typo in apiVersion or kind |
| Schema fields exist | Every `fromFieldPath` in patches must reference a field that exists in the XRD's OpenAPI schema | Field renamed in XRD but not in composition |
| Required fields have defaults | XRD required fields without defaults will cause validation failures | Missing default in XRD schema |
| Version alignment | Composition targets the correct XRD version (`spec.compositeTypeRef.apiVersion`) | Version mismatch after XRD update |

**Present findings:**
```markdown
## Composition ↔ XRD Alignment

| Check | Status | Details |
|-------|--------|---------|
| compositeTypeRef | ✓/✗ | [details] |
| Schema field coverage | ✓/✗ | [missing fields if any] |
| Required field defaults | ✓/✗ | [fields missing defaults] |
| Version match | ✓/✗ | [versions] |
```

---

### Step 3: Check Runtime Providers

Compositions depend on Crossplane providers being installed and healthy.

```bash
kubectl get providers                          # All installed providers
kubectl get providerconfig                     # All provider configurations
kubectl get controllerconfig 2>/dev/null       # Controller configs (if any)
```

**For each provider used by the composition:**
- Is it installed? (`kubectl get provider <name>`)
- Is it healthy? (check `Ready` condition)
- Does the ProviderConfig it references exist?

```markdown
## Provider Health

| Provider | Installed | Healthy | ProviderConfig Exists |
|----------|-----------|---------|----------------------|
| [name] | ✓/✗ | ✓/✗ | ✓/✗ |
```

---

### Step 4: Trace Patch Chains

This is the most common source of composition issues. For each patch in the composition:

```bash
kubectl get composition <name> -o json | jq '.spec.resources[].patches[]'
```

**For each patch, verify:**
1. `fromFieldPath` — does this field exist and have a value in the XR?
2. `toFieldPath` — is this a valid path in the composed resource schema?
3. `transforms` — are transform functions correct (map, convert, string)?
4. `policy.fromFieldPath` — is it `Required` or `Optional`? A `Required` patch with a missing source value will block the resource.

**If a live XR exists, verify actual values:**
```bash
kubectl get <xr-type> <xr-name> -o yaml
```

**Present as a patch flow diagram:**
```markdown
## Patch Chain Analysis

| Resource | From | → | To | Value | Status |
|----------|------|---|-----|-------|--------|
| [resource-name] | spec.parameters.region | → | spec.forProvider.region | "eu-west-1" | ✓ |
| [resource-name] | spec.parameters.size | → | spec.forProvider.instanceClass | null | ✗ MISSING |
```

Flag any patches where the source value is null, empty, or mismatched type.

---

### Step 5: Rendered vs Expected

If a live XR exists, compare what was actually composed against what the composition should have produced.

```bash
# Get composed resources from the XR
kubectl get <xr-type> <xr-name> -o jsonpath='{.spec.resourceRefs}'
```

For each composed resource:
```bash
kubectl get <kind> <name> -o yaml
```

**Compare key fields:**
- Do patched fields have the expected values?
- Are there fields that should have been set but are missing?
- Are there unexpected default values overriding patches?

```markdown
## Rendered vs Expected

| Resource | Field | Expected | Actual | Match |
|----------|-------|----------|--------|-------|
| [name] | spec.forProvider.region | eu-west-1 | eu-west-1 | ✓ |
| [name] | spec.forProvider.vpcId | vpc-abc123 | (empty) | ✗ |
```

---

### Step 6: RBAC and ProviderConfig

Check if the Crossplane provider has permission to create the resources the composition specifies.

**Identify the provider ServiceAccount:**
```bash
kubectl get provider <provider-name> -o jsonpath='{.status.currentRevision}'
kubectl get pods -n crossplane-system -l pkg.crossplane.io/revision=<revision> -o jsonpath='{.items[0].spec.serviceAccountName}'
```

**Check permissions for each composed resource type:**
```bash
kubectl auth can-i create <resource> --as=system:serviceaccount:crossplane-system:<sa-name>
kubectl auth can-i update <resource> --as=system:serviceaccount:crossplane-system:<sa-name>
```

**Check ProviderConfig references:**
For each composed resource that references a ProviderConfig:
```bash
kubectl get providerconfig <name> 2>/dev/null
```

```markdown
## RBAC & ProviderConfig

| Check | Resource | Result |
|-------|----------|--------|
| Can create | [resource-type] | ✓/✗ |
| ProviderConfig exists | [config-name] | ✓/✗ |
```

---

### Step 7: Diagnosis Summary

Compile all findings into a structured diagnosis:

```markdown
## Composition Diagnosis

**Resource:** [composition/xrd/xr name]

**Root Cause:** [The specific issue found — which step revealed it]

**Details:**
[Specific field, patch, RBAC rule, or ProviderConfig that is the problem]

**Recommended Fix:**
[Exact changes to make — file paths, field values, or commands]

**Verification:**
After applying the fix:
1. Re-apply the composition: `kubectl apply -f <composition-file>`
2. Check XR status: `kubectl get <xr-type> <xr-name> -o yaml`
3. Monitor with: `kaos-watch.sh <xr-type>/<xr-name> --show-tree --until Ready`
```

If no single root cause is found but multiple issues exist, list them in priority order (fix the first one, then re-run this skill).
