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
- [ ] **Stack Deployment:** Deploy the full Observability Stack via Helm:
    - **Logs:** Loki + Promtail (`loki-stack`)
    - **Visuals:** Grafana (`kube-prometheus-stack`)
    - **Tracing:** Tempo (`tempo`)
    - **Metrics:** Prometheus (`kube-prometheus-stack`)
- [ ] **Instrumentation:**
    - [ ] Update Python app with **OpenTelemetry** (for Tracing).
    - [ ] Expose `/metrics` endpoint (for Prometheus).
- [ ] **Configuration:**
    - [ ] Create **ServiceMonitor** to scrape app metrics.
    - [ ] Configure **Promtail** to ship logs to Loki.
- [ ] **Visualization:** Create "Golden Signals" Dashboard (RPS, Latency, Errors, Saturation).
- [ ] **Alerting:** Define SLIs/SLOs and configure Alertmanager.
- [ ] **Automation:** Create a `setup_cluster.sh` script to auto-install all Helm charts after cluster creation.

## Phase 4: State & Data (The Brain) ⏳
- [ ] **Database:** Provision **Cloud SQL (PostgreSQL)** via Terraform.
- [ ] **Networking:** Configure **Private Service Access** (Peering) for secure connectivity.
- [ ] **App Logic:** Update Python app to connect to DB (e.g., "Visitor Counter").
- [ ] **Secrets:** Use **Workload Identity** (IAM Auth) instead of passwords.
- [ ] **Migrations:** Implement a DB migration job (Flyway/Alembic) in the pipeline.

## Phase 5: Reliability & Scaling (The Muscles) ⏳
- [ ] **Probes:** Configure Liveness & Readiness Probes in `deployment.yaml`.
- [ ] **Pod Autoscaling (HPA):** Implement HPA based on CPU/Memory usage.
- [ ] **Event Autoscaling (KEDA):** Scale pods based on external events (e.g., HTTP traffic or Queue depth).
- [ ] **Optional:** Migrate to GKE Standard & Implement Karpenter/Node Scaling.
- [ ] **Load Testing:** Use `k6` to simulate traffic spikes and force the cluster to scale up.
- [ ] **PDB:** Configure Pod Disruption Budgets for zero-downtime upgrades.

## Phase 6: Advanced Traffic & Cleanup ⏳
- [ ] **Ingress:** Deploy **GCP Native Ingress** (L7 Global Load Balancer).
- [ ] **DNS:** Configure External DNS / TLS Certificates.
- [ ] **Refactoring:** Convert flat Terraform files into reusable **Terraform Modules**.
