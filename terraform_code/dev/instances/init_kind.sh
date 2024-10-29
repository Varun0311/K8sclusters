#!/bin/bash
set -ex

# Update packages and install Docker
sudo yum update -y
sudo yum install docker -y
sudo systemctl start docker

# Add the current user to the Docker group
sudo usermod -a -G docker ec2-user

# Install Kind
curl -sLo kind https://kind.sigs.k8s.io/dl/v0.11.0/kind-linux-amd64
sudo install -o root -g root -m 0755 kind /usr/local/bin/kind
rm -f ./kind

# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
rm -f ./kubectl

# Create the Kind cluster using the configuration file
kind create cluster --config kind.yaml
