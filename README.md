# EKS DevOps API Deployment

# Overview

This project is a production-grade deployment of a FastAPI devops tools  application on AWS EKS. The deployment spans three availability zones for high availability and uses EKS Managed Node Groups for scalability. Infrastructure is automated using Terraform, and the application is containerised using Docker and stored in Amazon ECR.
<img width="1875" height="1045" alt="image" src="https://github.com/user-attachments/assets/d8842a4a-3e91-48aa-ac3f-ed1586865694" />


# Architecture

![Untitled Diagram](https://github.com/user-attachments/assets/cad2a8a6-fb79-43ca-af4d-a6106e4f0032)


# Key Features

- **ExternalDNS**: Automatically updates DNS records in Route 53
- **Cert-Manager**: Provides automated SSL/TLS certificate management via Let's Encrypt
- **NGINX Ingress Controller**: Routes external traffic to services within the cluster and the service forwards to pods on port 8080
- **ArgoCD**: GitOps-based continuous deployment to update kubernetes manifests
- **Prometheus/Grafana**: Collects cluster metrics and visualises them in dashboards
- **IRSA (IAM Roles for Service Accounts)**: Uses temporary credentials via OIDC, eliminating the need for long-lived access keys

## Directory Structure

```
├── .github
│   └── workflows
│       ├── code-change-pipeline.yml
│       └── terraform-pipeline.yml
├── app
│   ├── Dockerfile
│   ├── main.py
│   └── requirements.txt
├── k8s
│   ├── clusterissuer.yml
│   ├── deployment.yml
│   ├── ingress.yml
│   └── service.yml
├── terraform
│   ├── backend.tf
│   ├── cert-manager-iam.tf
│   ├── ecr.tf
│   ├── eks.tf
│   ├── externaldns-iam.tf
│   ├── network.tf
│   ├── outputs.tf
│   └── provider.tf
├── .gitignore
└── README.md

```

## Infrastructure Components

### AWS Services

- **EKS Cluster**: Kubernetes with 3 worker nodes across 3 AZs
- **VPC**: VPC with public and private subnets
- **Route 53**: DNS management for jahirulmadethisinaws.online
- **ECR**: Private container registry
- **IAM**: IRSA roles for ExternalDNS and CertManager
- **STATE MANAGEMENT**: remote state stored in S3 and statelocking enabled via Dynamodb

### Kubernetes Components

- **Application**: FastAPI devops tools (2 replicas)
- **NGINX Ingress**: LoadBalancer Service creating AWS NLB
- **ExternalDNS**: Automated DNS record management
- **CertManager**: Automated SSL certificate issuance and renewal
- **ArgoCD**: GitOps continuous deployment
- **Prometheus/Grafana**: Monitoring and observability

## CI/CD Pipeline
<img width="1882" height="1008" alt="image" src="https://github.com/user-attachments/assets/1d6c0ae5-a45d-460b-a19f-7889cc5090cc" />
<img width="1909" height="1048" alt="image" src="https://github.com/user-attachments/assets/48195a0a-0a65-4bc0-9448-a26af6253684" />



### GitHub Actions Workflow for changes in /app folder

1. Triggered on push to `main` branch
2. Builds Docker image with commit SHA as tag
3. Pushes image to Amazon ECR
4. Updates `k8s/deployment.yml` with new image tag
5. Commits changes back to repository
6. ArgoCD detects changes and deploys automatically

### GitHub Actions Workflow for changes in /terraform folder

1. Runs Checkov security scan to validate infrastructure configurations
2. Checks for security best practices and compliance violations
3. Initialises Terraform with remote state backend
4. Validates Terraform configuration syntax
5. Runs `terraform plan` to preview infrastructure changes
6. Applies infrastructure changes automatically
7. Handles state management and locking

**Security checks include:**

- IAM policy least privilege validation
- Encryption at rest configurations
- Network security group rules
- Public accessibility checks

### Security

- **OIDC Authentication**: GitHub Actions authenticates to AWS without long-lived credentials
- **Trivy Scans**: Docker images scanned for vulnerabilities before deployment
- **Non-root Container**: Application runs as non-root user
- **Private Subnets**: Worker nodes isolated in private subnets

## GitOps with ArgoCD
<img width="1891" height="1033" alt="image" src="https://github.com/user-attachments/assets/7402e2b0-00c6-44b2-b58f-f3d1dba807f0" />


ArgoCD continuously monitors the GitHub repository and automatically syncs the cluster state with the desired state defined in Git. Any changes to Kubernetes manifests trigger automatic deployments.

## Monitoring
<img width="1890" height="1035" alt="image" src="https://github.com/user-attachments/assets/b135c6cb-1fde-4bd2-94e2-0af8e5bf41a1" />


### Prometheus

- Scrapes metrics from all cluster components every 15 seconds
- Monitors pod CPU, memory, network, and application metrics

### Grafana

- Visualises Prometheus data through pre-built dashboards
- Provides real-time insights into cluster health
- Accessible via port-forward: `kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80`

## DNS & SSL Automation

### ExternalDNS

- Watches Ingress resources for hostname annotations
- Creates A records in Route 53 automatically thorough IRSA access
- Updates records when LoadBalancer address changes

### CertManager

- Automatically requests SSL certificates from Let's Encrypt
- Uses DNS-01 challenge via Route 53
- Renews certificates before expiry
- Stores certificates in Kubernetes Secrets

## Deployment

### Prerequisites

- AWS CLI configured
- kubectl installed
- Terraform installed
- Helm installed

### Deploy Infrastructure

```bash
cd terraform/modules
terraform init
terraform apply

```

### Install Kubernetes Components

```bash
# NGINX Ingress
helm upgrade --install ingress-nginx ingress-nginx \\
  --repo <https://kubernetes.github.io/ingress-nginx> \\
  --namespace ingress-nginx \\
  --create-namespace

# ExternalDNS
helm install external-dns external-dns/external-dns \\
  --namespace external-dns \\
  --create-namespace \\
  --set provider=aws

# CertManager
helm install cert-manager jetstack/cert-manager \\
  --namespace cert-manager \\
  --create-namespace \\
  --set crds.enabled=true

# ArgoCD
kubectl create namespace argocd
kubectl apply -n argocd -f <https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml>

# Monitoring
helm install prometheus prometheus-community/kube-prometheus-stack \\
  --namespace monitoring \\
  --create-namespace

```

### Deploy Application

```bash
kubectl apply -f k8s/

```

## Access the Application

- **HTTP**: http://jahirulmadethisinaws.online
- **HTTPS**: https://jahirulmadethisinaws.online
note: I usually destroy unless I am actively presenting my project to avoid unneccessary costs 

## What I Learnt

### IRSA (IAM Roles for Service Accounts)

Understanding how Kubernetes ServiceAccounts can assume AWS IAM roles using OIDC was crucial. The trust policy conditions (`:sub` and `:aud`) must exactly match the ServiceAccount namespace and name, and pods must be restarted after annotation changes for environment variables to be injected.

### DNS-01 Challenge

CertManager uses DNS-01 challenge for wildcard certificates and when HTTP-01 isn't feasible. It creates TXT records in Route 53 that Let's Encrypt verifies before issuing certificates. This requires Route 53 permissions via IRSA.

### GitOps Benefits

Having Git as the single source of truth eliminates configuration drift. Any manual changes to the cluster are automatically reverted by ArgoCD, ensuring consistency and auditability.

## Future Improvements

- Implement Horizontal Pod Autoscaler (HPA)
- Add Vertical Pod Autoscaler (VPA)
- Configure AlertManager for Prometheus alerts
- Implement network policies for pod-to-pod communication
- Add Velero for cluster backups
