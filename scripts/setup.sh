#!/bin/bash

# Pull the necessary Docker images
docker pull vulnerables/web-dvwa
docker pull webgoat/webgoat-8.0
docker pull tenable/nessus:latest-ubuntu

# Start the containers using Docker Compose
docker-compose up -d

