#!/bin/bash

# ==========================================
# GCP SRE Project - Cluster Setup Script
# ==========================================
# This script automates the installation of the complete Observability Stack
# (Prometheus, Grafana, Loki, Promtail, Tempo) after cluster creation.
#
# Usage: ./setup_cluster.sh
# Prerequisites: kubectl and helm must be configured and authenticated
# ==========================================

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# ------------------------------------------
# Helpers
# ------------------------------------------
print_error_block() {
  local title="$1"
  local body="$2"
  echo -e "${RED}==========================================${NC}"
  echo -e "${RED}${title}${NC}"
  echo -e "${RED}==========================================${NC}"
  echo ""
  echo "${body}"
  echo ""
}

helm_upgrade_install_fast() {
  : <<'DOC'
  Runs "helm upgrade --install" WITHOUT --wait.
  Goal: be fast, but fail loudly with context + full helm output.
  Also verifies the resulting Helm release status is "deployed".
DOC
  local release="$1"
  local chart="$2"
  shift 2

  echo -e "${YELLOW}Helm: upgrade/install ${release} (${chart})...${NC}"

  local out
  if ! out="$(helm upgrade --install "${release}" "${chart}" "$@" 2>&1)"; then
    print_error_block "ERROR: Helm failed for release '${release}'" "${out}"
    exit 1
  fi

  local status_out
  if ! status_out="$(helm status "${release}" --namespace monitoring 2>&1)"; then
    print_error_block "ERROR: Helm succeeded but 'helm status' failed for release '${release}'" "${status_out}"
    echo "Helm output was:"
    echo "${out}"
    echo ""
    exit 1
  fi

  if ! echo "${status_out}" | grep -qE '^STATUS:[[:space:]]+deployed'; then
    print_error_block "ERROR: Release '${release}' is not deployed" "${status_out}"
    echo "Helm output was:"
    echo "${out}"
    echo ""
    exit 1
  fi

  echo -e "${GREEN}✓ Release '${release}' is deployed${NC}"
}

# Script directory (for relative paths)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MONITORING_DIR="${SCRIPT_DIR}/monitoring"

echo -e "${GREEN}==========================================${NC}"
echo -e "${GREEN}GCP SRE Project - Observability Stack Setup${NC}"
echo -e "${GREEN}==========================================${NC}"
echo ""

# Step 1: Add Helm Repositories
echo -e "${YELLOW}[1/6] Adding Helm repositories...${NC}"
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts || true
helm repo add grafana https://grafana.github.io/helm-charts || true
helm repo update

# Step 2: Create Monitoring Namespace
echo -e "${YELLOW}[2/6] Creating 'monitoring' namespace...${NC}"
kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -

# Step 3: Install kube-prometheus-stack (Prometheus + Grafana)
echo -e "${YELLOW}[3/6] Installing kube-prometheus-stack (Prometheus + Grafana)...${NC}"
helm_upgrade_install_fast kube-prometheus-stack prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --set grafana.adminPassword='admin' \
  --set prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues=false \
  --set nodeExporter.enabled=false \
  --set prometheus-node-exporter.enabled=false \
  --set kubeControllerManager.enabled=false \
  --set kubeScheduler.enabled=false \
  --set kubeEtcd.enabled=false \
  --set kubeProxy.enabled=false \
  --set coreDns.enabled=false

# Step 4: Install Loki (Log Aggregation)
echo -e "${YELLOW}[4/6] Installing Loki (Log Aggregation)...${NC}"
helm_upgrade_install_fast loki grafana/loki \
  --namespace monitoring \
  -f "${MONITORING_DIR}/loki-values.yaml"

# Step 5: Install Promtail (Log Shipper)
echo -e "${YELLOW}[5/6] Installing Promtail (Log Shipper)...${NC}"
helm_upgrade_install_fast promtail grafana/promtail \
  --namespace monitoring \
  -f "${MONITORING_DIR}/promtail-values.yaml"

# Step 6: Install Tempo (Distributed Tracing)
echo -e "${YELLOW}[6/6] Installing Tempo (Distributed Tracing)...${NC}"
helm_upgrade_install_fast tempo grafana/tempo \
  --namespace monitoring \
  -f "${MONITORING_DIR}/tempo-values.yaml"

# Step 7: Apply ServiceMonitor for Python App
echo -e "${YELLOW}[7/7] Applying ServiceMonitor for Python application...${NC}"
kubectl apply -f "${MONITORING_DIR}/servicemonitor.yaml"

# Summary
echo ""
echo -e "${GREEN}==========================================${NC}"
echo -e "${GREEN}Setup Complete!${NC}"
echo -e "${GREEN}==========================================${NC}"
echo ""
echo "Installed Components:"
echo "  ✓ Prometheus (Metrics Collection)"
echo "  ✓ Grafana (Visualization)"
echo "  ✓ Loki (Log Aggregation)"
echo "  ✓ Promtail (Log Shipper)"
echo "  ✓ Tempo (Distributed Tracing)"
echo "  ✓ ServiceMonitor (Python App Metrics)"
echo ""
echo "Access Grafana:"
echo "  kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 8080:80"
echo "  Then open: http://localhost:8080"
echo "  Username: admin"
echo "  Password: admin"
echo ""
echo "To check pod status:"
echo "  kubectl get pods -n monitoring"
echo ""

