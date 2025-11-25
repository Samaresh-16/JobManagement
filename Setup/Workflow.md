## How to run JobManagement:

# Start minikube
minikube start

# Delete existing pods if yml changes
kubectl delete all --all -n jobmgmt (if any changes in yml)

# Apply the k8s configurations
kubectl apply -f k8s/ -n jobmgmt

# Monitor the pods
kubectl get pods -n jobmgmt -w (monitor the running pods)

# Access the services
minikube service kafka-ui -n jobmgmt (tunnel the Kafka ui for visualization)
minikube service eureka-server -n jobmgmt (tunnel the eureka-server)
kubectl port-forward -n jobmgmt service/gateway 8080:8080 (port forwarding for testing)

# Workflow to test JobManagement microservice
Register users
## Important: Make sure to register at least one user with role 'ADMIN' for testing purpose.
Update one user to be admin to create cat, job and advertise: kubectl exec -it deployment/postgres -n jobmgmt -- psql -U postgres -d microservice -c "UPDATE users SET role = 'ADMIN' WHERE username = 'user01';"
User can now send job offers.