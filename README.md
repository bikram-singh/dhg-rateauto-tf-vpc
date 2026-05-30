# dhg-rateauto-tf-vpc

> **Terraform configuration to provision a production-grade, private Google Cloud VPC network for the DHG Rate Automation platform — including subnet with GKE secondary ranges, Cloud Router, Cloud NAT, VPC Flow Logs, and a default-deny firewall baseline.**

---

## 📋 Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Network Design](#network-design)
- [Repository Structure](#repository-structure)
- [Prerequisites](#prerequisites)
- [Resources Created](#resources-created)
- [Resource Deep Dive](#resource-deep-dive)
- [Variables Reference](#variables-reference)
- [Outputs Reference](#outputs-reference)
- [Environments](#environments)
- [CIDR Planning](#cidr-planning)
- [Usage](#usage)
- [CI/CD Pipeline](#cicd-pipeline)
- [Security Design](#security-design)
- [How It Connects to GKE](#how-it-connects-to-gke)
- [Provider Versions](#provider-versions)
- [Related Repositories](#related-repositories)

---

## Overview

This repository provisions the **foundational network layer** for the DHG Rate Automation platform on Google Cloud Platform. It is the first infrastructure component that must be deployed — all other resources (GKE clusters, Cloud SQL, GCS buckets) depend on this VPC.

The VPC follows a **private-by-default** architecture:
- GKE nodes have **no public IP addresses**
- Database traffic stays on **Google's private backbone** (PSC)
- Outbound internet access for nodes goes through **Cloud NAT** (not directly)
- All ingress is **denied by default**, with only intra-VPC traffic explicitly allowed
- VPC **Flow Logs** capture all traffic for audit and troubleshooting

This repo is deployed **once per environment** (dev, test, stage, prod) using environment-specific `.tfvars` files.

---

## Architecture

```
┌──────────────────────────────────────────────────────────────────────────┐
│                        GCP Project: dhg-vaccine-rateauto-nonpord          │
│                              Region: us-central1                          │
│                                                                            │
│  ┌─────────────────────────────────────────────────────────────────────┐  │
│  │                    VPC: dhg-rateauto-<env>-vpc                      │  │
│  │                    Routing Mode: REGIONAL                           │  │
│  │                                                                     │  │
│  │  ┌──────────────────────────────────────────────────────────────┐  │  │
│  │  │           Subnet: dhg-rateauto-<env>-subnet                  │  │  │
│  │  │           Primary CIDR:  10.x.0.0/20  (GKE Nodes)           │  │  │
│  │  │                                                              │  │  │
│  │  │   Secondary Range 1:  gke-pods      10.x.16.0/20            │  │  │
│  │  │   Secondary Range 2:  gke-services  10.x.32.0/24            │  │  │
│  │  │                                                              │  │  │
│  │  │   ✅ Private Google Access: enabled                          │  │  │
│  │  │   ✅ VPC Flow Logs: enabled (10min, 50% sampling)            │  │  │
│  │  └──────────────────────────────────────────────────────────────┘  │  │
│  │                                                                     │  │
│  │  ┌─────────────────┐    ┌──────────────────────────────────────┐   │  │
│  │  │  Cloud Router   │───▶│           Cloud NAT                  │   │  │
│  │  │  (vpc-router)   │    │  Auto IP allocation                  │   │  │
│  │  └─────────────────┘    │  All subnets + all IP ranges         │   │  │
│  │                         │  Error logging only                  │   │  │
│  │                         └──────────────────────────────────────┘   │  │
│  │                                              │                      │  │
│  │  ┌──────────────────────────────────┐        │ (outbound only)      │  │
│  │  │  Firewall Rules                  │        ▼                      │  │
│  │  │                                  │    Internet                   │  │
│  │  │  1. deny-all-ingress  P:65534    │    (image pulls, updates)     │  │
│  │  │     All protocols               │                               │  │
│  │  │     Source: 0.0.0.0/0           │                               │  │
│  │  │                                  │                               │  │
│  │  │  2. allow-internal   P:1000     │                               │  │
│  │  │     TCP + UDP + ICMP            │                               │  │
│  │  │     Source: VPC CIDRs only      │                               │  │
│  │  └──────────────────────────────────┘                               │  │
│  └─────────────────────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────────────────┘
```

---

## Network Design

### Why a Custom VPC?

Google Cloud creates a default VPC automatically, but it has several problems for production use:
- Auto-created subnets in every region (wasteful, harder to audit)
- No secondary ranges for GKE (needed for pod and service IPs)
- No Flow Logs by default
- Overly permissive default firewall rules

This custom VPC solves all of these by being purpose-built for the GKE workloads.

### Single Subnet Design

The VPC uses a **single subnet** with **three CIDR ranges**:

```
┌─────────────────────────────────────────────────────────┐
│                    Subnet (us-central1)                  │
│                                                          │
│  Primary CIDR   → GKE Node IPs   (e.g. 10.10.0.0/20)   │
│  Secondary 1    → GKE Pod IPs    (e.g. 10.10.16.0/20)   │
│  Secondary 2    → GKE Service IPs (e.g. 10.10.32.0/24)  │
└─────────────────────────────────────────────────────────┘
```

GKE requires secondary ranges because pods and services need their own IP space separate from the nodes — this avoids IP exhaustion and allows GKE to scale pods independently of node count.

### Private Google Access

```hcl
private_ip_google_access = true
```

This allows resources inside the subnet to reach Google APIs (Cloud Storage, Artifact Registry, Container Registry, etc.) **without a public IP** — traffic stays on Google's internal network. This is essential for GKE nodes to pull Docker images from GAR.

### Cloud NAT

Cloud NAT provides **outbound-only internet access** for private nodes:
- Nodes can pull OS updates, external packages etc.
- No inbound connections from internet are possible
- IP allocation is automatic (Google manages the NAT IPs)
- Only errors are logged (not every connection — that would be very noisy)

---

## Repository Structure

```
dhg-rateauto-tf-vpc/
│
├── .github/
│   └── workflows/
│       └── terraform.yml        # CI/CD: plan on PR, apply on merge to main
│
├── environments/
│   ├── dev.tfvars               # Development environment CIDRs and names
│   ├── test.tfvars              # Test environment CIDRs and names
│   ├── stage.tfvars             # Staging environment CIDRs and names
│   └── prod.tfvars              # Production environment CIDRs and names
│
├── main.tf                      # VPC, Subnet, Router, NAT, Firewall resources
├── variables.tf                 # All input variable definitions (70 lines)
├── outputs.tf                   # 10 output values consumed by GKE repo
├── providers.tf                 # Google provider configuration
├── versions.tf                  # Terraform + provider version constraints
└── README.md                    # This file
```

---

## Prerequisites

| Requirement | Details |
|---|---|
| **Terraform** | `>= 1.4` |
| **Google Provider** | `~> 5.0` |
| **GCP Project** | `dhg-vaccine-rateauto-nonpord` |
| **GCP APIs enabled** | `compute.googleapis.com` |
| **IAM permissions** | `roles/compute.networkAdmin`, `roles/compute.securityAdmin` |
| **Authentication** | WIF via GitHub Actions (CI/CD) or `gcloud auth application-default login` (local) |

Enable the Compute API if not already done:

```bash
gcloud services enable compute.googleapis.com \
  --project=dhg-vaccine-rateauto-nonpord
```

---

## Resources Created

| Resource | Terraform Name | Description |
|---|---|---|
| `google_compute_network` | `vpc` | Custom VPC network |
| `google_compute_subnetwork` | `subnet` | Single subnet with 2 secondary ranges |
| `google_compute_router` | `router` | Cloud Router (required for NAT) |
| `google_compute_router_nat` | `nat` | Cloud NAT for outbound internet access |
| `google_compute_firewall` | `deny_all_ingress` | Default-deny all inbound traffic |
| `google_compute_firewall` | `allow_internal` | Allow intra-VPC TCP/UDP/ICMP traffic |

**Total: 6 resources** provisioned per environment.

---

## Resource Deep Dive

### 1. VPC Network (`google_compute_network`)

```hcl
resource "google_compute_network" "vpc" {
  name                            = local.vpc_name
  project                         = var.project_id
  auto_create_subnetworks         = false   # Custom subnets only
  routing_mode                    = "REGIONAL"
  delete_default_routes_on_create = false
  description                     = "VPC network for ${var.stage} environment"
}
```

**Key decisions:**
- `auto_create_subnetworks = false` — We control exactly which subnets exist; no auto-created subnets in all regions
- `routing_mode = "REGIONAL"` — Routes are regional (not global); better isolation between environments
- `delete_default_routes_on_create = false` — Keeps the default internet route; Cloud NAT needs this to forward outbound traffic

---

### 2. Subnet (`google_compute_subnetwork`)

```hcl
resource "google_compute_subnetwork" "subnet" {
  name                     = local.subnet_name
  project                  = var.project_id
  region                   = var.region
  network                  = google_compute_network.vpc.id
  ip_cidr_range            = var.subnet_primary_cidr
  private_ip_google_access = true

  secondary_ip_range {
    range_name    = var.pods_range_name      # "gke-pods"
    ip_cidr_range = var.pods_cidr
  }

  secondary_ip_range {
    range_name    = var.services_range_name  # "gke-services"
    ip_cidr_range = var.services_cidr
  }

  log_config {
    aggregation_interval = "INTERVAL_10_MIN"
    flow_sampling        = 0.5               # 50% of flows logged
    metadata             = "INCLUDE_ALL_METADATA"
  }
}
```

**Key decisions:**
- **Two secondary ranges** are required by GKE — one for pod IPs, one for service (ClusterIP) IPs
- **Private Google Access** allows nodes to reach GCP APIs without a public IP
- **Flow Logs** at 50% sampling and 10-minute aggregation — enough for debugging without overwhelming Cloud Logging with costs
- `INCLUDE_ALL_METADATA` captures source/destination IPs, ports, protocols — essential for security auditing

---

### 3. Cloud Router (`google_compute_router`)

```hcl
resource "google_compute_router" "router" {
  name    = "${local.vpc_name}-router"
  project = var.project_id
  region  = var.region
  network = google_compute_network.vpc.id
}
```

The Cloud Router is a prerequisite for Cloud NAT. It uses **BGP** to advertise routes but in this configuration it simply enables NAT. No custom BGP configuration is needed since we are not using Cloud Interconnect or VPN.

---

### 4. Cloud NAT (`google_compute_router_nat`)

```hcl
resource "google_compute_router_nat" "nat" {
  name                               = "${local.vpc_name}-nat"
  project                            = var.project_id
  router                             = google_compute_router.router.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}
```

**Key decisions:**
- `nat_ip_allocate_option = "AUTO_ONLY"` — Google automatically allocates and manages NAT external IPs. This avoids the operational burden of reserving and managing static IPs
- `source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"` — All private IPs (nodes, pods, services) can use NAT for outbound traffic
- `filter = "ERRORS_ONLY"` — Logs only failed NAT translations, not every successful connection. This controls logging costs significantly

---

### 5. Firewall — Deny All Ingress (`google_compute_firewall`)

```hcl
resource "google_compute_firewall" "deny_all_ingress" {
  name      = "${local.vpc_name}-deny-all-ingress"
  project   = var.project_id
  network   = google_compute_network.vpc.id
  direction = "INGRESS"
  priority  = 65534

  deny {
    protocol = "all"
  }

  source_ranges = ["0.0.0.0/0"]
}
```

**Why this rule exists:**

GCP has an **implied allow-internal** rule at priority 65535 by default. By adding an explicit deny-all at priority 65534 (one higher = evaluated first), we override this default and establish a proper **zero-trust baseline**. Any allowed traffic must be explicitly permitted by a higher-priority allow rule (lower number = higher priority).

**Priority ladder:**
```
Priority 1000  → allow-internal     (explicit allow intra-VPC)
Priority 65534 → deny-all-ingress   (our explicit deny)
Priority 65535 → implied allow-all  (GCP default, never reached)
```

---

### 6. Firewall — Allow Internal (`google_compute_firewall`)

```hcl
resource "google_compute_firewall" "allow_internal" {
  name      = "${local.vpc_name}-allow-internal"
  project   = var.project_id
  network   = google_compute_network.vpc.id
  direction = "INGRESS"
  priority  = 1000

  allow { protocol = "tcp" }
  allow { protocol = "udp" }
  allow { protocol = "icmp" }

  source_ranges = [
    var.subnet_primary_cidr,  # Node CIDR
    var.pods_cidr,            # Pod CIDR
    var.services_cidr,        # Services CIDR
  ]
}
```

This rule allows all three major protocols within the VPC's own CIDR ranges. This is essential for:
- **TCP** — API calls between pods, Kubernetes control plane communication, health checks
- **UDP** — DNS resolution (kube-dns/CoreDNS uses UDP 53), some monitoring protocols
- **ICMP** — Ping for network connectivity testing and path MTU discovery

Traffic from outside these CIDRs is blocked by the deny-all rule.

---

## Variables Reference

### Identity & Location

| Variable | Type | Default | Required | Description |
|---|---|---|---|---|
| `project_id` | `string` | — | ✅ Yes | GCP project ID |
| `region` | `string` | `us-central1` | No | GCP region |
| `stage` | `string` | — | ✅ Yes | Environment label (`dev`, `test`, `stage`, `prod`) |

### Network Naming

| Variable | Type | Default | Required | Description |
|---|---|---|---|---|
| `network_name` | `string` | — | ✅ Yes | Name of the VPC network |
| `subnetwork_name` | `string` | — | ✅ Yes | Name of the subnet |

### CIDR Ranges

| Variable | Type | Default | Required | Description |
|---|---|---|---|---|
| `subnet_primary_cidr` | `string` | — | ✅ Yes | Primary CIDR for GKE nodes |
| `pods_range_name` | `string` | `gke-pods` | No | Secondary range name for GKE pods |
| `pods_cidr` | `string` | — | ✅ Yes | CIDR for GKE pod IPs |
| `services_range_name` | `string` | `gke-services` | No | Secondary range name for GKE services |
| `services_cidr` | `string` | — | ✅ Yes | CIDR for GKE service IPs |

### Labels

| Variable | Type | Default | Description |
|---|---|---|---|
| `resource_labels` | `map(string)` | `{}` | GCP labels applied to all resources |

---

## Outputs Reference

These outputs are consumed by the `dhg-rateauto-tf-gke` repository to connect the GKE cluster to this VPC.

| Output | Description | Used By |
|---|---|---|
| `network_name` | Name of the VPC network | GKE `network` argument |
| `network_id` | Self-link / ID of the VPC | Internal reference |
| `network_self_link` | Full URI of the VPC | GKE cluster config |
| `subnetwork_name` | Name of the subnet | GKE `subnetwork` argument |
| `subnetwork_self_link` | Full URI of the subnet | GKE cluster config |
| `subnet_primary_cidr` | Primary CIDR of the subnet | Firewall rule reference |
| `pods_range_name` | Secondary range name for pods | GKE `cluster_secondary_range_name` |
| `services_range_name` | Secondary range name for services | GKE `services_secondary_range_name` |
| `router_name` | Name of the Cloud Router | Operational reference |
| `nat_name` | Name of the Cloud NAT | Operational reference |

---

## Environments

Each environment gets its own VPC with non-overlapping CIDRs. This prevents IP conflicts if VPCs are ever peered.

### Example `environments/dev.tfvars`

```hcl
project_id      = "dhg-vaccine-rateauto-nonpord"
region          = "us-central1"
stage           = "dev"

network_name    = "dhg-rateauto-dev-vpc"
subnetwork_name = "dhg-rateauto-dev-subnet"

subnet_primary_cidr = "10.10.0.0/20"     # 4094 node IPs
pods_range_name     = "gke-pods"
pods_cidr           = "10.10.16.0/20"    # 4094 pod IPs
services_range_name = "gke-services"
services_cidr       = "10.10.32.0/24"    # 254 service IPs

resource_labels = {
  environment  = "dev"
  team         = "platform"
  managed-by   = "terraform"
}
```

---

## CIDR Planning

Careful CIDR planning ensures environments don't overlap and leaves room for future growth.

### Recommended CIDR Allocation

| Environment | Nodes (Primary) | Pods (Secondary 1) | Services (Secondary 2) |
|---|---|---|---|
| **dev** | `10.10.0.0/20` | `10.10.16.0/20` | `10.10.32.0/24` |
| **test** | `10.20.0.0/20` | `10.20.16.0/20` | `10.20.32.0/24` |
| **stage** | `10.30.0.0/20` | `10.30.16.0/20` | `10.30.32.0/24` |
| **prod** | `10.40.0.0/20` | `10.40.16.0/20` | `10.40.32.0/24` |

### IP Capacity

| CIDR | Size | Usable IPs | Purpose |
|---|---|---|---|
| `/20` | 4,096 | 4,094 | GKE nodes or pods |
| `/24` | 256 | 254 | GKE services (ClusterIPs) |

### GKE CIDR Requirements

GKE Autopilot has specific requirements:
- **Node CIDR** — Minimum `/29` (6 IPs), recommended `/20` or larger
- **Pod CIDR** — GKE allocates a `/24` per node by default, so `/20` supports up to 16 nodes with full pod density
- **Services CIDR** — Must not overlap with nodes or pods; `/24` gives 254 ClusterIP services

---

## Usage

### Local Development

```bash
# 1. Clone the repo
git clone https://github.com/bikram-singh/dhg-rateauto-tf-vpc.git
cd dhg-rateauto-tf-vpc

# 2. Authenticate with GCP
gcloud auth application-default login

# 3. Initialise Terraform (downloads provider plugins)
terraform init

# 4. Plan for dev environment — review what will be created
terraform plan -var-file=environments/dev.tfvars -out=tfplan

# 5. Apply the plan
terraform apply -auto-approve -input=false tfplan

# 6. View outputs (used by GKE repo)
terraform output
```

### View All Outputs

```bash
terraform output network_name
terraform output subnetwork_name
terraform output pods_range_name
terraform output services_range_name
```

### Destroy (when needed)

```bash
# ⚠️ Destroying VPC will break GKE clusters — destroy GKE first!
terraform destroy -var-file=environments/dev.tfvars
```

---

## CI/CD Pipeline

The `.github/workflows/terraform.yml` pipeline automates plan and apply using **Workload Identity Federation** — no service account JSON keys stored anywhere.

### Pipeline Flow

```
On Pull Request (any branch → main):
  ├── terraform fmt -check
  ├── terraform init
  ├── terraform validate
  └── terraform plan -var-file=environments/<env>.tfvars
        └── Posts plan output as PR comment

On Push to main:
  ├── terraform init
  ├── terraform plan -var-file=environments/<env>.tfvars -out=tfplan
  └── terraform apply -auto-approve -input=false tfplan
```

### WIF Authentication (No JSON Keys)

```yaml
- name: Authenticate to GCP
  uses: google-github-actions/auth@v2
  with:
    workload_identity_provider: >-
      projects/PROJECT_NUMBER/locations/global/workloadIdentityPools/
      dhg-rateauto-wif-pool/providers/github-oidc
    service_account: >-
      dhg-vpc-tf-sa@dhg-vaccine-rateauto-nonpord.iam.gserviceaccount.com
```

The service account needs these roles:
```
roles/compute.networkAdmin     → Create/modify VPC, subnets, routers
roles/compute.securityAdmin    → Create/modify firewall rules
roles/iam.serviceAccountUser   → Impersonate the SA
```

---

## Security Design

This VPC follows a **defence-in-depth** approach with multiple security layers:

### Layer 1 — Network Isolation
```
Private nodes → No public IPs on any GKE node
Private DB    → Cloud SQL accessed via PSC (private IP only)
Private APIs  → Private Google Access (no internet hop)
```

### Layer 2 — Firewall Policy
```
Default deny   → All inbound blocked at priority 65534
Explicit allow → Only intra-VPC traffic permitted
No SSH         → No firewall rule for port 22 (GKE Autopilot has no SSH anyway)
No HTTP/HTTPS  → Ingress handled by GKE Gateway, not VPC firewall
```

### Layer 3 — Outbound Control
```
Cloud NAT      → Controlled outbound path (auto-managed IPs)
No direct egress → Nodes cannot be directly reached from internet
```

### Layer 4 — Observability
```
VPC Flow Logs  → 50% sampling, all metadata, 10min aggregation
NAT Logs       → Error-level logging for failed translations
Cloud Logging  → All logs exported to Cloud Logging
```

### Layer 5 — Infrastructure as Code Security
```
WIF            → No long-lived service account keys
Terraform state → Remote state with locking (no local state files)
PR reviews     → All changes via pull request with plan preview
```

---

## How It Connects to GKE

The VPC outputs are consumed directly by the `dhg-rateauto-tf-gke` repository:

```hcl
# In dhg-rateauto-tf-gke/variables.tfvars
network_name         = "dhg-rateauto-dev-vpc"      # ← vpc output: network_name
subnetwork_name      = "dhg-rateauto-dev-subnet"   # ← vpc output: subnetwork_name
pods_range_name      = "gke-pods"                   # ← vpc output: pods_range_name
services_range_name  = "gke-services"               # ← vpc output: services_range_name

# In dhg-rateauto-tf-gke/main.tf
resource "google_container_cluster" "gke" {
  network    = var.network_name
  subnetwork = var.subnetwork_name

  ip_allocation_policy {
    cluster_secondary_range_name  = var.pods_range_name
    services_secondary_range_name = var.services_range_name
  }

  private_cluster_config {
    enable_private_nodes    = true   # Nodes use subnet primary CIDR
    enable_private_endpoint = false  # Control plane reachable externally
  }
}
```

**Dependency order — always deploy in this sequence:**

```
1. dhg-rateauto-tf-vpc          ← This repo (foundation)
2. dhg-rateauto-tf-gke          ← Needs VPC outputs
3. dhg-rateauto-tf-gke-routing  ← Needs GKE cluster
4. dhg-rateauto-tf-gcs-buckets  ← Independent (GCS only)
```

---

## Provider Versions

```hcl
# versions.tf
terraform {
  required_version = ">= 1.4"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

# providers.tf
provider "google" {
  project = var.project_id
  region  = var.region
}
```

> **Note:** The `~> 5.0` constraint means any version `>= 5.0.0` and `< 6.0.0`. This is more permissive than the GCS bucket repo which uses `< 6.11.0` — both are compatible with GCP resources used here.

---

## Related Repositories

| Repository | Purpose | Depends On |
|---|---|---|
| **`dhg-rateauto-tf-vpc`** | **This repo** — VPC, subnet, NAT, firewall | Nothing (deployed first) |
| `dhg-rateauto-tf-gke` | GKE Autopilot clusters | VPC outputs |
| `dhg-rateauto-tf-gke-routing` | Gateway API, HTTPRoutes, SSL | GKE cluster |
| `dhg-rateauto-tf-gcs-buckets` | GCS bucket provisioning | Independent |
| `dhg-rateauto-api-backend` | FastAPI backend application | GKE + VPC |
| `dhg-rateauto-ui-frontend` | React frontend dashboard | GKE + VPC |

---

## Maintainer

**Bikram Singh**
- GCP Project: `dhg-vaccine-rateauto-nonpord`
- Region: `us-central1`
- Repository: `github.com/bikram-singh/dhg-rateauto-tf-vpc`
