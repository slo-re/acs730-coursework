#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

CONF="$HOME/.kube/lab7-deployer.conf"
NS=lab7

kubectl config use-context kind-acs730 >/dev/null
kubectl apply -f lab7/k8s/namespace.yaml
kubectl apply -f lab7/k8s/rbac.yaml

TOKEN="$(kubectl -n "$NS" create token lab7-deployer --duration=24h)"

mkdir -p "$HOME/.kube"
kubectl config view --minify --raw > "$CONF"
chmod 600 "$CONF"

KUBECONFIG="$CONF" kubectl config unset users >/dev/null
KUBECONFIG="$CONF" kubectl config set-credentials lab7-deployer \
  --token="$TOKEN" >/dev/null

KUBECONFIG="$CONF" kubectl config set-context --current \
  --user=lab7-deployer --namespace="$NS" >/dev/null

echo "Limited-access Kubernetes permissions:"
echo -n "Patch deployments: "
KUBECONFIG="$CONF" kubectl auth can-i patch deployments -n "$NS"
echo -n "Delete deployments: "
KUBECONFIG="$CONF" kubectl auth can-i delete deployments -n "$NS" || true
echo -n "Read secrets: "
KUBECONFIG="$CONF" kubectl auth can-i get secrets -n "$NS" || true
echo -n "Create namespaces: "
KUBECONFIG="$CONF" kubectl auth can-i create namespaces || true
echo -n "Delete nodes: "
KUBECONFIG="$CONF" kubectl auth can-i delete nodes || true
