#!/usr/bin/env bash

# ------------------------------------------------------------
# LoanTrack one‑click deployment script
# ------------------------------------------------------------
# This script applies the Kubernetes manifests that compose the
# LoanTrack three‑tier application. It assumes you have a cluster
# (e.g., minikube, kind, or a remote cluster) with kubectl
# configured and that the required Docker images are already built
# and available to the cluster (either via a local registry or
# Docker Desktop's internal registry).
# ------------------------------------------------------------

set -euo pipefail

# Optional: build Docker images locally (requires Docker)
# Uncomment the lines below if you want the script to rebuild the images.
# echo "Building Docker images..."
# docker build -t loantrack-backend:latest ./backend
# docker build -t loantrack-frontend:latest ./frontend

# Apply the namespace (creates it if it does not exist)
kubectl apply -f k8s/namespace.yaml

# Apply ConfigMap and Secret (you may need to replace the placeholder values)
kubectl apply -f k8s/configmap.yaml
kubectl apply -f k8s/secret.example.yaml

# Deploy PostgreSQL (StatefulSet + Service)
kubectl apply -f k8s/postgres-statefulset.yaml
kubectl apply -f k8s/postgres-service.yaml

# Deploy Backend and Frontend workloads
kubectl apply -f k8s/backend-deployment.yaml
kubectl apply -f k8s/backend-service.yaml
kubectl apply -f k8s/frontend-deployment.yaml
kubectl apply -f k8s/frontend-service.yaml

# Wait for all pods to become ready (simple check)
echo "Waiting for pods to be ready..."
kubectl wait --for=condition=ready pod -l app=postgres --timeout=120s || true
kubectl wait --for=condition=ready pod -l app=backend --timeout=120s || true
kubectl wait --for=condition=ready pod -l app=frontend --timeout=120s || true

echo "✅ Deployment completed."

# Optional: expose the frontend via NodePort (already defined in the Service)
# To get the URL, run:
#   kubectl get svc frontend -n loantrack -o jsonpath='{.spec.ports[0].nodePort}'
#   echo "http://$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type==\"InternalIP\").address}'):<nodePort>"
