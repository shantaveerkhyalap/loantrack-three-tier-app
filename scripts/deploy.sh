#!/usr/bin/env bash

# ============================================================
# LoanTrack — one-command deploy script (E2)
# ============================================================
# Usage:  ./scripts/deploy.sh
#
# Pre-requisites:
#   • minikube running  →  minikube start
#   • kubectl configured to the minikube context
#   • k8s/secret.yaml present (copy from k8s/secret.example.yaml
#     and fill in real values — never commit the real file)
#
# This script is idempotent: running it a second time is safe.
# ============================================================

set -euo pipefail

# Check if Minikube is installed
if ! command -v minikube >/dev/null 2>&1; then
    echo "Minikube is not installed."
    echo "Install it: https://minikube.sigs.k8s.io/docs/start/"
    exit 1
fi

# Check if Minikube is running
if [[ "$(minikube status --format='{{.Host}}')" != "Running" ]]; then
    echo "Minikube is not running."
    echo "Start it first:"
    echo "    minikube start"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# ── 0. Sanity checks ─────────────────────────────────────────
if ! command -v minikube &>/dev/null; then
  echo "minikube not found. Install it first: https://minikube.sigs.k8s.io/docs/start/"
  exit 1
fi

if ! command -v kubectl &>/dev/null; then
  echo "kubectl not found."
  exit 1
fi

if [[ ! -f "${REPO_ROOT}/k8s/secret.yaml" ]]; then
  echo "k8s/secret.yaml not found."
  echo "    Copy k8s/secret.example.yaml → k8s/secret.yaml and fill in real credentials."
  exit 1
fi

echo "Pointing Docker CLI at minikube's internal daemon..."
eval "$(minikube docker-env)"

export DOCKER_BUILDKIT=0

# ── 1. Build Docker images inside minikube ───────────────────
echo ""
echo "Building loantrack-backend:latest ..."
docker build -t loantrack-backend:latest "${REPO_ROOT}/backend"

echo ""
echo "Building loantrack-frontend:latest ..."
docker build -t loantrack-frontend:latest "${REPO_ROOT}/frontend"

# ── 2. Apply manifests in dependency order ───────────────────
echo ""
echo "  Applying Kubernetes manifests..."

kubectl apply -f "${REPO_ROOT}/k8s/namespace.yaml"

kubectl apply -f "${REPO_ROOT}/k8s/configmap.yaml"
kubectl apply -f "${REPO_ROOT}/k8s/secret.yaml"
kubectl apply -f "${REPO_ROOT}/k8s/postgres-init-configmap.yaml"

kubectl apply -f "${REPO_ROOT}/k8s/postgres-statefulset.yaml"
kubectl apply -f "${REPO_ROOT}/k8s/postgres-service.yaml"

kubectl apply -f "${REPO_ROOT}/k8s/backend-deployment.yaml"
kubectl apply -f "${REPO_ROOT}/k8s/backend-service.yaml"

kubectl apply -f "${REPO_ROOT}/k8s/frontend-deployment.yaml"
kubectl apply -f "${REPO_ROOT}/k8s/frontend-service.yaml"

# ── 3. Wait for rollouts ─────────────────────────────────────
echo ""
echo "Waiting for PostgreSQL to be ready (up to 3 min)..."
kubectl rollout status statefulset/postgres -n loantrack --timeout=180s

echo "Waiting for backend rollout..."
kubectl rollout status deployment/backend -n loantrack --timeout=120s

echo "Waiting for frontend rollout..."
kubectl rollout status deployment/frontend -n loantrack --timeout=120s

# ── 4. Print access URL ──────────────────────────────────────
echo ""
echo "Deployment complete!"
echo ""

NODE_IP=$(minikube ip)
NODE_PORT=$(kubectl get svc frontend -n loantrack \
  -o jsonpath='{.spec.ports[0].nodePort}' 2>/dev/null || echo "30080")

echo "   Open the app at:  http://${NODE_IP}:${NODE_PORT}"
echo ""
echo "    Or run:  minikube service frontend -n loantrack --url"
echo "   Do -> kubectl port-forward svc/frontend -n loantrack -p 8080:80"
echo ""
echo "  Cluster overview:"
kubectl get all -n loantrack
