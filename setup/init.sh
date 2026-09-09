#!/bin/bash
set -e

echo "=== Movie Picture Pipeline: Cluster Configuration ==="
echo "Configuring AWS credentials and updating Kubernetes configuration..."

CLUSTER_NAME=$(cd terraform && terraform output -raw cluster_name 2>/dev/null || echo "mp-cluster")
AWS_REGION=$(cd terraform && terraform output -raw region 2>/dev/null || echo "us-east-1")
IAM_USER_ARN=$(cd terraform && terraform output -raw github_action_user_arn 2>/dev/null || echo "arn:aws:iam::123456789012:user/github-action-user")

echo "Updating kubeconfig for EKS cluster: ${CLUSTER_NAME} in ${AWS_REGION}..."
aws eks update-kubeconfig --name "${CLUSTER_NAME}" --region "${AWS_REGION}" || true

echo "Downloading eksctl/aws-auth mapping helper tool..."
curl -sL -o /tmp/eksctl.tar.gz "https://github.com/eksctl-io/eksctl/releases/latest/download/eksctl_Linux_amd64.tar.gz" 2>/dev/null || true
tar -xzf /tmp/eksctl.tar.gz -C /tmp 2>/dev/null || true

if [ -x /tmp/eksctl ]; then
    echo "Adding IAM user ARN ${IAM_USER_ARN} to Kubernetes aws-auth ConfigMap..."
    /tmp/eksctl create iamidentitymapping \
        --cluster "${CLUSTER_NAME}" \
        --region "${AWS_REGION}" \
        --arn "${IAM_USER_ARN}" \
        --group "system:masters" \
        --username "github-action-user" || true
    rm -f /tmp/eksctl /tmp/eksctl.tar.gz
fi

echo "Done"
