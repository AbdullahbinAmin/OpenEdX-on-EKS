#!/bin/bash
# Al Nafi OpenEdX Cluster Setup Script
# Purpose: Reconnect to EKS and verify core components

CLUSTER_NAME="alnafi-cluster"
REGION="us-east-1"

echo "Updating Kubeconfig for $CLUSTER_NAME..."
aws eks update-kubeconfig --region $REGION --name $CLUSTER_NAME

echo "Verifying Nodes..."
kubectl get nodes

echo "Checking OpenEdX Namespace..."
kubectl get pods -n openedx

echo "Verifying Ingress Controller..."
kubectl get svc -n ingress-nginx

echo "Setup Verification Complete."
