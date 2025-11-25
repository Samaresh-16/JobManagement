#!/bin/bash

set -e  # Exit on any error

echo "🚀 JobManagement Minikube Setup Script for macOS"
echo "=================================================="
echo ""

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# Check if Homebrew is installed
print_step "Checking for Homebrew..."
if ! command -v brew &> /dev/null; then
    print_warning "Homebrew not found. Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Add Homebrew to PATH for Apple Silicon Macs
    if [[ $(uname -m) == 'arm64' ]]; then
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
    print_info "✅ Homebrew installed successfully"
else
    print_info "✅ Homebrew is already installed"
fi

# Check if Docker is installed
print_step "Checking for Docker..."
if ! command -v docker &> /dev/null; then
    print_warning "Docker not found. Installing Docker Desktop..."
    brew install --cask docker
    print_info "✅ Docker Desktop installed"
    print_warning "Please start Docker Desktop from Applications folder"
    print_warning "Wait for the Docker whale icon to show in the menu bar"
    print_warning "Press Enter once Docker Desktop is running..."
    read
else
    print_info "✅ Docker is already installed"

    # Check if Docker is running
    if ! docker info &> /dev/null; then
        print_warning "Docker is installed but not running"
        print_warning "Please start Docker Desktop from Applications and wait..."
        print_warning "Press Enter once Docker Desktop is running..."
        read

        # Verify Docker is now running
        if ! docker info &> /dev/null; then
            print_error "Docker is still not running. Please start Docker Desktop and try again."
            exit 1
        fi
    fi
    print_info "✅ Docker is running"
fi

# Install kubectl
print_step "Checking for kubectl..."
if ! command -v kubectl &> /dev/null; then
    print_warning "kubectl not found. Installing kubectl..."
    brew install kubectl
    print_info "✅ kubectl installed successfully"
else
    KUBECTL_VERSION=$(kubectl version --client --short 2>/dev/null | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' || kubectl version --client -o json 2>/dev/null | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' | head -1)
    print_info "✅ kubectl is already installed (${KUBECTL_VERSION})"
fi

# Install Minikube
print_step "Checking for Minikube..."
if ! command -v minikube &> /dev/null; then
    print_warning "Minikube not found. Installing Minikube..."
    brew install minikube
    print_info "✅ Minikube installed successfully"
else
    MINIKUBE_VERSION=$(minikube version --short 2>/dev/null || echo "installed")
    print_info "✅ Minikube is already installed (${MINIKUBE_VERSION})"
fi

echo ""
echo "=================================================="
print_info "All prerequisites are installed!"
echo "=================================================="
echo ""

# Check if Minikube is running
print_step "Checking Minikube status..."
if minikube status &> /dev/null; then
    print_info "Minikube cluster is already running"
    read -p "Do you want to delete and restart Minikube cluster? (y/n): " restart
    if [ "$restart" = "y" ] || [ "$restart" = "Y" ]; then
        print_info "Deleting existing Minikube cluster..."
        minikube delete
        print_info "Starting fresh Minikube cluster..."
        minikube start --driver=docker --memory=4096 --cpus=2
    else
        print_info "Using existing Minikube cluster"
    fi
else
    print_info "Starting new Minikube cluster..."
    minikube start --driver=docker --memory=4096 --cpus=2
fi

# Verify Minikube is running
echo ""
print_step "Verifying Minikube cluster..."
if ! minikube status &> /dev/null; then
    print_error "Failed to start Minikube. Please check Docker is running and try again."
    exit 1
fi
print_info "✅ Minikube cluster is running"

# Create namespace
print_step "Setting up Kubernetes namespace..."
if kubectl get namespace jobmgmt &> /dev/null; then
    print_info "Namespace 'jobmgmt' already exists"
else
    kubectl create namespace jobmgmt
    print_info "✅ Namespace 'jobmgmt' created"
fi

# Prompt for GHCR credentials (only if private)
echo ""
print_step "GitHub Container Registry Setup"
read -p "Are your GHCR images private? (y/n): " private
if [ "$private" = "y" ] || [ "$private" = "Y" ]; then
    print_info "Setting up GitHub Container Registry authentication..."
    echo ""
    read -p "GitHub Username: " gh_user
    read -sp "GitHub Personal Access Token (PAT): " gh_pat
    echo ""
    read -p "Email: " gh_email

    # Delete existing secret if it exists
    if kubectl get secret ghcr-secret -n jobmgmt &> /dev/null; then
        print_info "Updating existing GHCR secret..."
        kubectl delete secret ghcr-secret -n jobmgmt
    fi

    kubectl create secret docker-registry ghcr-secret \
      --docker-server=ghcr.io \
      --docker-username=$gh_user \
      --docker-password=$gh_pat \
      --docker-email=$gh_email \
      --namespace=jobmgmt

    print_info "✅ GHCR authentication configured"
else
    print_info "Skipping GHCR authentication (using public images)"
fi

# Check if k8s directory exists
echo ""
print_step "Deploying Kubernetes resources..."
if [ ! -d "k8s" ]; then
    print_error "k8s directory not found!"
    print_error "Please ensure you're running this script from the project root directory."
    exit 1
fi

# Deploy all services
print_info "Applying Kubernetes manifests from k8s/ directory..."
kubectl apply -f k8s/

echo ""
print_info "Waiting for deployments to be ready (this may take a few minutes)..."
echo ""

# Wait for all deployments with better feedback
DEPLOYMENTS=$(kubectl get deployments -n jobmgmt -o jsonpath='{.items[*].metadata.name}')
if [ -n "$DEPLOYMENTS" ]; then
    for deployment in $DEPLOYMENTS; do
        print_info "Waiting for $deployment..."
        kubectl wait --for=condition=available deployment/$deployment -n jobmgmt --timeout=300s 2>/dev/null || print_warning "$deployment is taking longer than expected"
    done
else
    print_warning "No deployments found in jobmgmt namespace"
fi

# Show pod status
echo ""
echo "=================================================="
print_info "Deployment Status"
echo "=================================================="
echo ""
kubectl get pods -n jobmgmt -o wide

# Show services
echo ""
print_info "Services:"
kubectl get services -n jobmgmt

echo ""
echo "=================================================="
print_info "✅ Setup Complete!"
echo "=================================================="
echo ""
print_info "Useful Commands:"
echo ""
echo "  📊 View all pods:"
echo "     kubectl get pods -n jobmgmt"
echo ""
echo "  📋 View pod logs:"
echo "     kubectl logs <pod-name> -n jobmgmt"
echo "     kubectl logs -f <pod-name> -n jobmgmt  # Follow logs"
echo ""
echo "  🌐 Access services:"
echo "     minikube service <service-name> -n jobmgmt --url"
echo "     minikube service list -n jobmgmt  # List all services"
echo ""
echo "  🎛️  Minikube dashboard:"
echo "     minikube dashboard"
echo ""
echo "  🔄 Restart a deployment:"
echo "     kubectl rollout restart deployment/<deployment-name> -n jobmgmt"
echo ""
echo "  ⏸️  Stop Minikube:"
echo "     minikube stop"
echo ""
echo "  🗑️  Delete Minikube cluster:"
echo "     minikube delete"
echo ""

# Get service URLs
echo "=================================================="
print_info "Service URLs"
echo "=================================================="
echo ""

SERVICES=$(kubectl get services -n jobmgmt -o jsonpath='{.items[?(@.spec.type=="NodePort")].metadata.name}')
if [ -n "$SERVICES" ]; then
    for service in $SERVICES; do
        URL=$(minikube service $service -n jobmgmt --url 2>/dev/null || echo "N/A")
        echo "  🔗 $service: $URL"
    done
else
    print_warning "No NodePort services found"
fi

echo ""
print_info "Happy coding! 🎉"
echo ""