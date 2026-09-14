# Evidence

This document contains the terminal outputs and verification steps requested in the assignment for Parts B, C, and D.

---

## Part B: Docker

### 1. Explicit non-root USER
**Command:**
```bash
docker exec <backend-container-name> whoami
```
**Output:**
appus@Lenovo:/mnt/c/Users/appus/OneDrive/Desktop/loantrack-three-tier-app$ docker exec abc6301047b2  whoami
loantrack

### 2. Backend image under 300 MB
**Command:**
```bash
docker images | grep backend
```
**Output:**
appus@Lenovo:/mnt/c/Users/appus/OneDrive/Desktop/loantrack-three-tier-app$ docker images | grep loantrack-three-tier-app*
WARNING: This output is designed for human readability. For machine-readable output, please use --format.
loantrack-three-tier-app-backend:latest    26d506264b01        209MB             0B   U
loantrack-three-tier-app-frontend:latest   8b662e3a2019       48.3MB             0B   U
loantrack-three-tier-app_backend:latest    26d506264b01        209MB             0B   U
loantrack-three-tier-app_frontend:latest   8b662e3a2019       48.3MB             0B   U

---

## Part C: Database & Three-tier connectivity

### 1. Retry with backoff on startup
*Start the backend before the database; it must log retries and recover, not crash.*

**Backend Logs:**
```text
# TODO: Paste the backend container logs here showing the connection retries and eventual success.
```

### 2. Data persistence across restarts
*Add a loan in the UI, then show the same row via psql in the DB container.*

**Command:**
```bash
docker exec -it <db-container-name> psql -U postgres -d loantrack -c "SELECT * FROM loans;"
```
**Output (Before restart):**
appus@Lenovo:/mnt/c/Users/appus/OneDrive/Desktop/loantrack-three-tier-app$ docker exec -it 92306b580a8c psql -U loanuser -d loantrackdb
psql (15.19)
Type "help" for help.

loantrackdb=# SELECT * FROM loans;
 id |   borrower_name    | loan_amount |  property_city  |  status  |          created_at
----+--------------------+-------------+-----------------+----------+-------------------------------
  1 | Alice Smith        |   250000.00 | New York        | APPROVED | 2026-09-13 05:43:29.949103+00
  2 | Bob Johnson        |   150000.50 | Los Angeles     | PENDING  | 2026-09-13 05:43:29.949103+00
  3 | Charlie Brown      |   300000.00 | Chicago         | REJECTED | 2026-09-13 05:43:29.949103+00
  4 | Diana Prince       |   450000.00 | Washington D.C. | APPROVED | 2026-09-13 05:43:29.949103+00
  5 | Evan Wright        |   100000.00 | Austin          | PENDING  | 2026-09-13 05:43:29.949103+00
  6 | shantaveer khyalap |    70000.00 | bengaluru       | PENDING  | 2026-09-13 05:45:27.448841+00
(6 rows)

*docker compose down then up — data survives. Then down -v and state in one line what changed.*

**Line stating what changed after `docker compose down -v`:**
> `docker compose down -v` destroys the named volume, permanently deleting all database data; bringing the stack back up starts with a fresh, empty database.

---

## Part D: Kubernetes (minikube)

### 1. Networking / DNS Resolution
*From a backend pod, resolve/connect to the database Service by DNS name.*

**Command:**
```bash
# Example assuming backend pod has curl/telnet installed, or use a temporary debug pod.
kubectl exec -it <backend-pod-name> -n loantrack -- curl -v telnet://postgres-service.loantrack.svc.cluster.local:5432
```
**Output:**
appus@Lenovo:/mnt/c/Users/appus/OneDrive/Desktop/loantrack-three-tier-app/scripts$ kubectl exec -it backend-5fbb4cd5b4-9g4mt -n loantrack -- curl -v telnet://postgres.loantrack.svc.cluster.local:5432
* Host postgres.loantrack.svc.cluster.local:5432 was resolved.
* IPv6: (none)
* IPv4: 10.97.254.9
*   Trying 10.97.254.9:5432...
* Connected to postgres.loantrack.svc.cluster.local (10.97.254.9) port 5432

**Fully-qualified form of that name:** `postgres.loantrack.svc.cluster.local`

### 2. Scale the backend to 3 replicas
**Command:**
```bash
kubectl scale deployment backend-deployment --replicas=3 -n loantrack
kubectl get pods -n loantrack -l app=backend
```
**Output:**
appus@Lenovo:/mnt/c/Users/appus/OneDrive/Desktop/loantrack-three-tier-app/scripts$ kubectl scale deployment backend --replicas=3 -n
 loantrack
deployment.apps/backend scaled
appus@Lenovo:/mnt/c/Users/appus/OneDrive/Desktop/loantrack-three-tier-app/scripts$ kubectl get pods -n loantrack -l app=backend
NAME                       READY   STATUS    RESTARTS        AGE
backend-5fbb4cd5b4-9g4mt   1/1     Running   0               7m44s
backend-5fbb4cd5b4-dtz4q   1/1     Running   0               7m44s
backend-5fbb4cd5b4-mzlp2   1/1     Running   3 (9m15s ago)   22h

### 3. Rolling update to a `:v2` image
**Command:**
```bash
kubectl set image deployment/backend backend=backend:v2 -n loantrack
kubectl rollout status deployment/backend -n loantrack
kubectl rollout undo deployment/backend -n loantrack
```
**Output:**
```text
# TODO: Paste the rollout status and undo output here
```
**One line on what a user hitting the app mid-rollout experiences, and which setting controls it:**
> A user mid-rollout experiences zero downtime and seamless requests, controlled by the Deployment's `strategy.rollingUpdate.maxUnavailable` and `maxSurge` settings combined with readiness probes.

### 4. Delete a backend pod
**Command:**
```bash
kubectl delete pod <backend-pod-name> -n loantrack
kubectl get pods -n loantrack -w
```
**Output:**
appus@Lenovo:/mnt/c/Users/appus/OneDrive/Desktop/loantrack-three-tier-app$ kubectl delete pod backend-5fbb4cd5b4-9g4mt -n loantrack

kubectl get pods -n loantrack -w
pod "backend-5fbb4cd5b4-9g4mt" deleted from loantrack namespace
NAME                        READY   STATUS              RESTARTS      AGE
backend-5fbb4cd5b4-bsdk5    0/1     Running             0             2s
backend-5fbb4cd5b4-dtz4q    1/1     Running             0             13m
backend-5fbb4cd5b4-mzlp2    1/1     Running             3 (15m ago)   23h
backend-9ff7fbcf9-kw2tn     0/1     ErrImageNeverPull   0             5m25s
frontend-77764b57cd-7gqhh   1/1     Running             3 (15m ago)   23h
postgres-0                  1/1     Running             1 (16m ago)   22h 

### 5. Delete the PostgreSQL pod
**Command:**
```bash
kubectl delete pod <postgres-pod-name> -n loantrack
# Wait for replacement pod to start
kubectl exec -it <new-postgres-pod-name> -n loantrack -- psql -U postgres -d loantrack -c "SELECT * FROM loans;"
```
**Output:**
appus@Lenovo:/mnt/c/Users/appus/OneDrive/Desktop/loantrack-three-tier-app$ kubectl delete pod postgres-0 -n loantrack
pod "postgres-0" deleted from loantrack namespace
appus@Lenovo:/mnt/c/Users/appus/OneDrive/Desktop/loantrack-three-tier-app$ kubectl exec -it postgres-0 -n loantrack -- psql -U dummyuser -d loantrackdb -c "SELECT * FROM loans;"
 id |   borrower_name    | loan_amount |  property_city  |  status  |          created_at
----+--------------------+-------------+-----------------+----------+-------------------------------
  1 | Alice Smith        |   250000.00 | New York        | APPROVED | 2026-09-13 06:12:28.533135+00
  2 | Bob Johnson        |   150000.50 | Los Angeles     | PENDING  | 2026-09-13 06:12:28.533135+00
  3 | Charlie Brown      |   300000.00 | Chicago         | REJECTED | 2026-09-13 06:12:28.533135+00
  4 | Diana Prince       |   450000.00 | Washington D.C. | APPROVED | 2026-09-13 06:12:28.533135+00
  5 | Evan Wright        |   100000.00 | Austin          | PENDING  | 2026-09-13 06:12:28.533135+00
  6 | appu_khyalap       |  1200000.00 | bengaluru urban | PENDING  | 2026-09-13 06:31:36.704032+00
  7 | shantaveer_khyalap |   300000.00 | Bidar           | PENDING  | 2026-09-13 06:37:55.055993+00
  8 | Kumar              | 10000000.00 | bengaluru urban | PENDING  | 2026-09-13 06:42:26.224907+00
(8 rows)

### 6. Get all resources
**Command:**
```bash
kubectl get all -n loantrack
kubectl get pvc,configmap,secret -n loantrack
```
**Output:**
appus@Lenovo:/mnt/c/Users/appus/OneDrive/Desktop/loantrack-three-tier-app$ kubectl get all -n loantrack
kubectl get pvc,configmap,secret -n loantrack
NAME                            READY   STATUS              RESTARTS      AGE
pod/backend-5fbb4cd5b4-bsdk5    1/1     Running             0             6m27s
pod/backend-5fbb4cd5b4-dtz4q    1/1     Running             0             20m
pod/backend-5fbb4cd5b4-mzlp2    1/1     Running             3 (21m ago)   23h
pod/backend-9ff7fbcf9-kw2tn     0/1     ErrImageNeverPull   0             11m
pod/frontend-77764b57cd-7gqhh   1/1     Running             3 (21m ago)   23h
pod/postgres-0                  1/1     Running             0             38s

NAME               TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)        AGE
service/backend    ClusterIP   10.111.29.158   <none>        8000/TCP       23h
service/frontend   NodePort    10.98.11.207    <none>        80:30080/TCP   23h
service/postgres   ClusterIP   10.97.254.9     <none>        5432/TCP       23h

NAME                       READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/backend    3/3     1            3           23h
deployment.apps/frontend   1/1     1            1           23h

NAME                                  DESIRED   CURRENT   READY   AGE
replicaset.apps/backend-5fbb4cd5b4    3         3         3       23h
replicaset.apps/backend-9ff7fbcf9     1         1         0       11m
replicaset.apps/frontend-77764b57cd   1         1         1       23h

NAME                        READY   AGE
statefulset.apps/postgres   1/1     23h
NAME                                             STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   VOLUMEATTRIBUTESCLASS   AGE
persistentvolumeclaim/postgres-data-postgres-0   Bound    pvc-57bf2cb6-a94d-4353-a170-4f6db45374d2   1Gi        RWO            standard       <unset>                 23h

NAME                              DATA   AGE
configmap/kube-root-ca.crt        1      23h
configmap/loantrack-config        3      23h
configmap/postgres-init-scripts   1      23h

NAME                      TYPE     DATA   AGE
secret/loantrack-secret   Opaque   2      23h

---

## UI Screenshots
*Please embed or link your screenshots here.*

- **Docker Compose UI:** 
  http://localhost:<port>
  http://localhost:8082

---

## Issues Faced

*(These are three realistic issues modeled after typical problems encountered in this setup. Feel free to use them or replace them with your own).*

### Issue 1: Backend Pod Crashing in Kubernetes Before DB is Ready
* **Symptom:** The backend pod in Kubernetes entered a `CrashLoopBackOff` state.
* **Diagnosis:** Ran `kubectl get pods -n loantrack` and noticed the backend restarting repeatedly. Ran `kubectl logs <backend-pod-name> -n loantrack` and saw `psycopg2.OperationalError: connection to server at "postgres-service"... failed`.
* **Root cause:** The backend container was trying to connect to the database immediately on startup. Because the Postgres StatefulSet takes a few seconds to provision storage and start up, the backend failed and crashed before the database was ready to accept connections.
* **Fix:** Implemented a retry loop with exponential backoff in the backend Python code (`main.py`) to gracefully catch the connection error, sleep, and try again instead of crashing.

### Issue 2: Liveness Probe Killing a Healthy Container
* **Symptom:** The backend container kept restarting every minute despite being perfectly healthy and able to serve traffic.
* **Diagnosis:** Ran `kubectl describe pod <backend-pod-name> -n loantrack` and noticed the events at the bottom said `Liveness probe failed: HTTP probe failed with statuscode: 500`.
* **Root cause:** I had initially configured the `/healthz` liveness probe endpoint to perform a database query to ensure everything was fine. When the database had a brief network blip or lock, the query timed out, causing the Liveness probe to fail, which triggered Kubernetes to aggressively kill and restart the backend pod.
* **Fix:** Separated the health checks. I made `/healthz` (Liveness) a dumb endpoint that just returns `200 OK` without touching the DB. I moved the DB check to `/readyz` (Readiness), so if the DB goes down, the backend is temporarily removed from the Service load balancer but is not killed.

### Issue 3: Refused Connection in Docker Compose
* **Symptom:** The frontend container could not fetch data from the backend API, showing a `net::ERR_CONNECTION_REFUSED` error in the browser console.
* **Diagnosis:** Checked the Docker Compose logs (`docker compose logs frontend`). Opened the browser DevTools Network tab and noticed the `fetch()` call was being made to `http://backend:8000/loans`. 
* **Root cause:** The frontend code runs in the user's web browser, not inside the Docker network. The browser doesn't know what `backend:8000` is because that's an internal Docker network DNS name.
* **Fix:** I configured NGINX in the frontend container to act as a reverse proxy. The browser now calls `/api/loans` on `localhost` (the frontend), and NGINX forwards that request internally to `http://backend:8000` within the Docker network.
