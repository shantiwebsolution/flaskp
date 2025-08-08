#!/bin/bash

# Set variables
REGION="ap-south-1"
ACCOUNT_ID="417447013917"
FRONTEND_REPO="${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/front-end"
BACKEND_REPO="${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/back-end"

# Login to ECR
aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin ${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com

# Build and push frontend
cd frontend2
docker build -t frontend2 .
docker tag frontend2:latest $FRONTEND_REPO:latest
docker push $FRONTEND_REPO:latest
cd ..

# Build and push backend
cd backend
docker build -t backend .
docker tag backend:latest $BACKEND_REPO:latest
docker push $BACKEND_REPO:latest
cd ..

echo "Build and push completed successfully."
