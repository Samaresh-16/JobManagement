# JobManagement Local Development Setup (macOS)

## Quick Start

1. Clone the repository:
```bash
   git clone https://github.com/Samaresh-16/JobManagement.git
   cd JobManagement
```

2. Run the setup script: <b>Not tested suggest manual installation if issues arise</b>
```bash
   cd Setup
   chmod +x setup.sh
   ./setup.sh
```

3. Follow the prompts:
    - If Docker Desktop installation is triggered, wait for it to complete
    - Launch Docker Desktop from Applications
    - Continue the script when Docker is running
    - Provide GitHub credentials if images are private

## Manual Installation (if script fails)
```bash
# Install Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install Docker Desktop
brew install --cask docker

# Install kubectl
brew install kubectl

# Install Minikube
brew install minikube

# Start Minikube
minikube start --driver=docker --memory=4096 --cpus=2

# Create namespace
kubectl create namespace jobmgmt

# Deploy services
kubectl apply -f ../k8s/ -n jobmgmt

# Monitor pods
kubectl get pods -n jobmgmt --watch
```

## Accessing Services

After successful deployment:
```bash
# Get eureka-server URL
minikube service auth-service -n jobmgmt

# Get Kafka ui URL
minikube service kafka-ui -n jobmgmt

# Get all service URLs
minikube service list -n jobmgmt
```

## Troubleshooting

### Docker not starting
- Open Docker Desktop from Applications
- Wait for whale icon to show "running"

### Minikube won't start
```bash
minikube delete
minikube start --driver=docker --memory=4096 --cpus=2
```

### ImagePullBackOff error
```bash
# Verify secret exists
kubectl get secrets -n jobmgmt

# Check pod logs
kubectl describe pod <pod-name> -n jobmgmt
```

## Useful Commands
```bash
# View logs
kubectl logs -f <pod-name> -n jobmgmt

# Restart deployment
kubectl rollout restart deployment/<deployment-name> -n jobmgmt

# Open Kubernetes dashboard
minikube dashboard

# Stop Minikube (preserves cluster)
minikube stop

# Delete Minikube (clean slate)
minikube delete
```