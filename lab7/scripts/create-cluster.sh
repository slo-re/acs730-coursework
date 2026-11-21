#!/usr/bin/env bash
set -euo pipefail

CLUSTER="acs730"
NS="lab7"
TAG="${1:-v1}"
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

if kind get clusters 2>/dev/null | grep -qx "$CLUSTER"; then
  kind delete cluster --name "$CLUSTER"
fi

kind create cluster --config lab7/kind-cluster.yaml
kubectl wait --for=condition=Ready nodes --all --timeout=180s

docker build -t "acs730-lab4:$TAG" lab4/
kind load docker-image "acs730-lab4:$TAG" --name "$CLUSTER"

if [ -f lab7/k8s/namespace.yaml ]; then
  kubectl apply -f lab7/k8s/namespace.yaml
fi

if [ -f lab7/k8s/deployment.yaml ]; then
  kubectl apply -f lab7/k8s/
  kubectl -n "$NS" rollout status \
    deployment/acs730-lab4 --timeout=180s
fi

if [ -x lab7/scripts/mint-deployer-kubeconfig.sh ]; then
  ./lab7/scripts/mint-deployer-kubeconfig.sh
fi

echo "Cluster ready: http://localhost:30080/healthz"
