# Child Cluster Access

To verify resources on the child KubePool cluster, you need its kubeconfig.

## Method 1: Via ClusterAuth Secret (Recommended)

The EKS ClusterAuth creates a connection secret in the KubeOrg namespace:

```bash
# 1. Find the connection secret
KUBECONFIG=~/.kube/config kubectl get secret -n <org-namespace> | grep ekscluster

# 2. Extract kubeconfig
KUBECONFIG=~/.kube/config kubectl get secret <secret-name> -n <org-namespace> \
  -o jsonpath='{.data.kubeconfig}' | base64 -d > /tmp/child-kubeconfig.yaml

# 3. Use it
export KUBECONFIG=/tmp/child-kubeconfig.yaml
kubectl get nodes
```

**Note:** EKS tokens expire in ~15 minutes. Re-run the extract command to refresh.

## Method 2: Via get-kubeconfig Script

If available:
```bash
KUBECONFIG=~/.kube/config /path/to/scripts/get-kubeconfig.sh <clusterauth-name>
export KUBECONFIG=scripts/kubeconfig.yaml
```

## Finding the Secret Name

```bash
# List ClusterAuth resources
KUBECONFIG=~/.kube/config kubectl get clusterauth -A

# The secret name follows: {uid}-ekscluster
KUBECONFIG=~/.kube/config kubectl get secret -n <org-namespace> | grep ekscluster
```
