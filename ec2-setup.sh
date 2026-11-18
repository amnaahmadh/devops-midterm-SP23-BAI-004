#!/bin/bash
# Run on a fresh Ubuntu 22.04/24.04 EC2:  bash ec2-setup.sh
set -e

# 2 GB swap so Jenkins + pip + docker build don't run out of RAM on small instances
if ! swapon --show | grep -q swapfile; then
  sudo fallocate -l 2G /swapfile && sudo chmod 600 /swapfile
  sudo mkswap /swapfile && sudo swapon /swapfile
  echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
fi

sudo apt-get update -y
sudo apt-get install -y fontconfig openjdk-17-jre git curl docker.io python3 python3-venv python3-pip

# Jenkins
sudo wget -O /usr/share/keyrings/jenkins-keyring.asc https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key
echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" | \
  sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null
sudo apt-get update -y
sudo apt-get install -y jenkins

# Let Jenkins run docker
sudo usermod -aG docker jenkins
sudo usermod -aG docker ubuntu
sudo systemctl enable --now docker
sudo systemctl restart jenkins

echo "=========================================="
echo "Jenkins initial admin password:"
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
echo "Open: http://$(curl -s ifconfig.me):8080"
