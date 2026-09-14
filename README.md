# LoanTrack

A simple three-tier application (Frontend, API backend, PostgreSQL) deployed on Kubernetes.

## Tool Versions Used
- **Docker:** 24.0.5
- **minikube:** v1.32.0
- **kubectl:** v1.29.0
- **runtime:** Docker

## Architecture Diagram

```ascii
     +-------------------+
     |   User Browser    |
     +---------+---------+
               | HTTP (NodePort)
               v
     +---------+---------+
     |   Frontend (UI)   |
     +---------+---------+
               | HTTP (Port 8000)
               v
     +---------+---------+
     |   API Backend     |
     +---------+---------+
               | TCP (Port 5432)
               v
     +---------+---------+
     |    PostgreSQL     |
     +-------------------+
```

## Run Instructions

### Docker Compose
To run the application locally using Docker Compose:

```bash
# 1. Copy the example env file
cp .env.example .env

# 2. Start the application
docker compose up -d

# 3. Access the frontend in your browser (usually http://localhost)
```

### Kubernetes
To deploy the application to a local Kubernetes cluster (minikube):

```bash
# 1. Start minikube
minikube start

# 2. Point your shell to minikube's docker-daemon, then build images if needed
eval $(minikube docker-env)

export DOCKER_BUILDKIT=0

# 3. Create a real secret from the example (ensure you base64 encode values)
cp k8s/secret.example.yaml k8s/secret.yaml
# Edit k8s/secret.yaml to include actual base64 encoded credentials

# 4. Apply all Kubernetes manifests
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/

# 5. Access the frontend service
minikube service frontend-service -n loantrack
```

## Design Decisions
- **Backend base image choice:** We used `python:3.12-slim` to have a smaller image footprint while still providing standard tools and a shell, reducing the attack surface without the complexity of Alpine.
- **Layer-cache boundary:** We copy `requirements.txt` and run `pip install` before copying the application code, ensuring dependencies are cached across rebuilds unless the requirements file itself changes.
- **StatefulSet vs Deployment for Postgres:** We chose StatefulSet for Postgres to provide stable network identifiers and ordered deployment/scaling, and guarantees stable persistent storage which is crucial for a database.
- **Liveness vs Readiness:** Liveness checks if the app is dead and needs a restart (e.g., process hung), while Readiness checks if the app is ready to receive traffic (e.g., database is connected).
- **Exceeding Memory Limit vs CPU Limit:** If a container exceeds its memory limit it is typically OOMKilled by the node, while exceeding its CPU limit simply results in the container being CPU throttled (running slower).
- **Base64 in Secrets:** Base64 is merely encoding (not encryption) and can be easily decoded by anyone; in production, you should use a KMS, HashiCorp Vault, AWS Secrets Manager, or tools like External Secrets Operator.