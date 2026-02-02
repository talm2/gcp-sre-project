# SRE Portfolio Project - Roadmap

This document tracks the progress of building a production-grade SRE environment on GCP.

## Phase 1: Foundation (Infrastructure) ✅
- [x] Create GCP Project & Service Account.
- [x] Configure Terraform with GCS Backend (State).
- [x] **Networking:** Custom VPC, Subnets, Cloud Router, Cloud NAT.
- [x] **Compute:** GKE Autopilot Cluster.
- [x] **Security:** Workload Identity Federation for GitHub Actions.

## Phase 2: Application & CI/CD ✅
- [x] Python Flask App with `/` and `/error` routes.
- [x] Dockerfile (Multi-stage build).
- [x] GitHub Actions Pipeline:
    - [x] Build & Push to Artifact Registry.
    - [x] Deploy to GKE (Dynamic Image Tagging).
- [ ] **Advanced CI/CD:** Deploy Helm Charts via GitHub Actions (Package the app as a Helm Chart).

## Phase 3: Observability (LGTM Stack) 🚧
- [x] **Stack Deployment:** Deploy the full Observability Stack via Helm:
    - [x] **Logs:** Loki + Promtail (`loki`)
    - [x] **Visuals:** Grafana (`kube-prometheus-stack`)
    - [x] **Tracing:** Tempo (`tempo`)
    - [x] **Metrics:** Prometheus (`kube-prometheus-stack`)
- [x] **Instrumentation:**
    - [x] Update Python app with **OpenTelemetry** (for Tracing).
    - [x] Expose `/metrics` endpoint (for Prometheus).
- [x] **Configuration:**
    - [x] Create **ServiceMonitor** to scrape app metrics.
    - [x] Configure **Promtail** to ship logs to Loki.
- [ ] **Visualization:** Create "Golden Signals" Dashboard (RPS, Latency, Errors, Saturation).
- [ ] **Visualization:** Create cluster capacity dashboard
- [ ] **Alerting:** Define SLIs/SLOs and configure Alertmanager.
- [x] **Automation:** Create a `setup_cluster.sh` script to auto-install all Helm charts after cluster creation.

## Phase 4: State & Data - Foundation (The Brain) ⏳
- [ ] **Database:** Provision **Cloud SQL (PostgreSQL)** via Terraform (backups enabled). (DevOps/IaC)
- [ ] **Networking:** Configure **Private Service Access** + Cloud SQL Private IP. (DevOps/IaC)
- [ ] **Connectivity Check:** Verify GKE → Cloud SQL connectivity (port 5432) from a pod. (DevOps/IaC)
- [ ] **Auth/Security:** Start with simple secrets (Kubernetes Secrets). (DevOps/IaC)
- [ ] **App Logic:** Add DB-backed feature (e.g., "Visitor Counter" / items table):
    - [ ] INSERT endpoint
    - [ ] SELECT by key endpoint
    - [ ] filter + order query endpoint (Dev)
- [ ] **Migrations:** Add Alembic/Flyway migration job in the pipeline (safe change pattern). (DevOps)
- [ ] **Auth/Security:** Migrate to **Workload Identity** for the app (avoid long-lived static keys). (DevOps/IaC)

## Phase 4.6: Database Observability ⏳
- [ ] **Metrics:** DB query latency histogram, DB errors counter, pool usage. (SRE-Critical)
- [ ] **Traces:** Spans for DB calls (OTel). (SRE-Critical)
- [ ] **Dashboard:** DB "Golden Signals" (latency/errors/traffic/saturation). (SRE-Critical)

## Phase 4.7: Database Performance & Resilience ⏳
- [ ] **Connection Pooling:** Add pooling + sane limits (and test under load). (SRE-Critical)
- [ ] **Performance:** Generate ~100k rows + run Index + EXPLAIN before/after. (SRE-Critical)
- [ ] **SRE Drills:** Run 2 short drills and capture evidence:
    - [ ] Pool exhaustion → observe latency/errors (SRE-Critical)
    - [ ] Lock/long transaction → observe p99 jump/timeouts (SRE-Critical)
- [ ] **Runbook:** 1-page "DB latency high" checklist. (SRE-Critical)

## Phase 5: Cloud Logging (GCP-Native Ops) ⏳
- [ ] **Structured logs:** Ensure app logs are JSON and include:
    - [ ] service, env, severity, message
    - [ ] request_id
    - [ ] trace_id, span_id
- [ ] **Logs Explorer basics (GKE):**
    - [ ] Find your app logs under `k8s_container` / `gke_container`
    - [ ] Filter by cluster / namespace / pod / container
    - [ ] Filter by severity >= ERROR
- [ ] **Correlation drill (logs ↔ traces):**
    - [ ] Trigger `/error`
    - [ ] Find the error log in Cloud Logging
    - [ ] Copy `trace_id` and locate the matching trace in Tempo/Grafana
- [ ] **“Missing logs” drill (basic diagnosis):**
    - [ ] Simulate “no logs found” (wrong filters / wrong resource / wrong namespace)
    - [ ] Fix it by narrowing correctly: resource → cluster → namespace → pod → container
- [ ] **Audit awareness (one example):**
    - [ ] Locate one audit log entry (e.g., IAM change / GKE API call)
    - [ ] Identify the actor + action + time
- [ ] **Optional:** Sink: Export ERROR logs of your service to GCS

## Phase 6: Reliability & Scaling (The Muscles) ⏳
- [ ] **Probes:** Configure Liveness & Readiness Probes in `deployment.yaml`.
- [ ] **Pod Autoscaling (HPA):** Implement HPA based on CPU/Memory usage.
- [ ] **Event Autoscaling (KEDA):** Scale pods based on external events (e.g., HTTP traffic or Queue depth).
- [ ] **Optional:** Migrate to GKE Standard & Implement Karpenter/Node Scaling.
- [ ] **Load Testing:** Use `k6` to simulate traffic spikes and force the cluster to scale up.
- [ ] **PDB:** Configure Pod Disruption Budgets for zero-downtime upgrades.

## Phase 7: Enterprise CI/CD (The Factory) ⏳
- [ ] **GitOps:** Install and configure **ArgoCD** to manage cluster state.
- [ ] **Jenkins/AWX:** Deploy Jenkins/AWX (on-prem/VM) to simulate legacy enterprise pipelines interacting with K8s.

## Phase 8: Advanced Traffic & Cleanup ⏳
- [ ] **Ingress:** Deploy **GCP Native Ingress** (L7 Global Load Balancer).
- [ ] **DNS:** Configure External DNS / TLS Certificates.
- [ ] **Refactoring:** Convert flat Terraform files into reusable **Terraform Modules**.
- [ ] **Refactoring:** re-install env for karpenter.
## Phase 9: Advanced gCP ⏳
- [ ] **Refactoring:** based on the TF chat