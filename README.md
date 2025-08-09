# Deploying an Nginx Application on Kubernetes with Kind and NodePort

This guide walks you through setting up a Kubernetes cluster using **Kind** (Kubernetes in Docker) and deploying a simple Nginx web application with a `NodePort` Service for external access.

## Prerequisites
- Docker installed and running on your system.
- Kind installed (`go install sigs.k8s.io/kind@v0.23.0` or download from [Kind releases](https://kind.sigs.k8s.io/docs/user/quick-start/#installation)).
- `kubectl` installed and configured.
- Basic understanding of YAML and `kubectl` commands.

## Steps to Deploy

### Step 1: Install Kind (if not already installed)

On Linux/MacOS:
```bash
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.23.0/kind-linux-amd64
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind
```

Verify installation:

```bash
kind version
```

### Step 2: Create a Kind Cluster

Create a simple Kind cluster with one control-plane node:

```bash
kind create cluster --name nginx-cluster
```

**Explanation:**

- This command creates a Kubernetes cluster named `nginx-cluster` inside Docker containers.
- Kind automatically configures kubectl to connect to this cluster.

Verify the cluster:


```bash
kubectl cluster-info --context kind-nginx-cluster
kubectl get nodes
```


Expected output:

```bash
NAME                        STATUS   ROLES           AGE   VERSION
nginx-cluster-control-plane Ready    control-plane   2m    v1.27.3
```

### Step 3: Create the Nginx Deployment File

Create a file named `nginx-deployment.yaml` with the following content:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
  labels:
    app: nginx
spec:
  replicas: 3 # Number of desired pods
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:latest # Official Nginx image from Docker Hub
        ports:
        - containerPort: 80 # Nginx listens on port 80
```

**Explanation:**

- The Deployment ensures 3 Nginx pods are running.
- Each pod uses the nginx:latest image and exposes port 80.

### Step 4: Create the NodePort Service File

Create a file named `nginx-service.yaml` with the following content:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx-service
spec:
  selector:
    app: nginx # Links to pods with label "app: nginx"
  ports:
    - protocol: TCP
      port: 80 # Service port
      targetPort: 80 # Pod port (Nginx)
      nodePort: 30007 # External port on the node (range: 30000-32767)
  type: NodePort # Service type
```

**Explanation:**

- The NodePort Service exposes Nginx on port 30007 of the Kind node.
- Traffic to <Node_IP>:30007 will be routed to port 80 of the Nginx pods.

### Step 5: Deploy the Application to Kubernetes

#### 1. Apply the Deployment:

```bash
kubectl apply -f nginx-deployment.yaml
```

Expected output:

```bash
deployment.apps/nginx-deployment created
```

#### 2. Apply the Service:

```bash
kubectl apply -f nginx-service.yaml
```

Expected output:

``` bash
service/nginx-service created
```

### Step 6: Verify the Deployment

#### 1. Check the pods:

```bash
kubectl get pods   
```

#### 2. Check the Service:

``` bash
kubectl get service
```

### Step 7: Access the Nginx Application

#### 1. Get the IP of the Kind cluster node:

Since Kind runs inside Docker, the node IP is typically localhost (or 127.0.0.1) when accessing from your host machine.
Alternatively, find the container IP: 

``` bash
docker inspect nginx-cluster-control-plane | grep IPAddress
```

Look for the IP under `"IPAddress"`, e.g., `172.18.0.2`.


#### 2. Access Nginx

Open a browser or use `curl`:

```bash
curl http://IPAddress:30007
```

