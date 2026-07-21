# Stop the script immediately if any command fails (equivalent to 'set -e' in Bash)
$ErrorActionPreference = "Stop"

Write-Host "Deploying app to EKS..." -ForegroundColor Green

# Update kubeconfig
aws eks update-kubeconfig --name production-eks --region us-east-1

# Apply Kubernetes manifests
kubectl apply -f clusterissuer.yaml
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
kubectl apply -f ingress.yaml 
kubectl apply -f argocd.yaml

Write-Host "Deployment complete" -ForegroundColor Cyan