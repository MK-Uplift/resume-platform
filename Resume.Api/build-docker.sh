#!/bin/bash

# Build Docker image locally
echo "Building Docker image..."
docker build -t resume-api:local .

echo ""
echo "✅ Docker image built successfully!"
echo ""
echo "To run locally:"
echo "docker run -p 8080:8080 -e ConnectionStrings__DefaultConnection='YOUR_CONNECTION_STRING' resume-api:local"
