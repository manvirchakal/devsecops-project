#!/bin/bash

# Update package lists
sudo apt-get update

# Install Docker if not already installed
if ! [ -x "$(command -v docker)" ]; then
  echo "Installing Docker..."
  sudo apt-get install -y docker.io
  sudo systemctl start docker
  sudo systemctl enable docker
fi

# Install Docker Compose if not already installed
if ! [ -x "$(command -v docker-compose)" ]; then
  echo "Installing Docker Compose..."
  sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
  sudo chmod +x /usr/local/bin/docker-compose
fi

# Create Docker network
docker network create my-network

# Deploy Juice Shop container
docker run -d --name juice-shop --network my-network bkimminich/juice-shop

# Deploy WebGoat container
docker run -d --name webgoat --network my-network webgoat/webgoat-8.0

# Deploy Nessus container
docker pull tenable/nessus
docker run -d --name nessus --network my-network -p 8834:8834 tenable/nessus

echo "Setup complete. Access your services at the following URLs:"
echo "Juice Shop: http://<your-vm-ip>:3000"
echo "WebGoat: http://<your-vm-ip>:8080"
echo "Nessus: https://<your-vm-ip>:8834"

