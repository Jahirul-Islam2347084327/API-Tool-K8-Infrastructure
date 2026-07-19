#!/bin/bash 
set -e 

echo "Deploying app to eks"

aws eks update-kubeconfig --name production-eks --region us-east-1


kubectl apply -f clusterissuer.yaml
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
kubectl apply -f ingress.yaml 
kubectl apply -f argocd.yaml

echo "Deployment complete"