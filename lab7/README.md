# Lab 7 - Kubernetes and CI/CD

## Kubernetes Fundamentals (Week 9)

### Tool Versions
This lab uses kubectl v1.31.1, kind v0.24.0, and kubeconform v0.8.0. These versions are pinned to keep the lab consistent and avoid compatibility issues.

### Why kind Instead of EKS?
I used kind because it runs Kubernetes using Docker on my existing EC2 workstation. Although EKS is available in the AWS account, its control plane has additional hourly costs. Kind helps conserve the $50 AWS Academy lab budget.

### Kubernetes Label Selectors
The Deployment uses matchLabels to identify the pods it manages. The Service uses its own selector to identify which pods receive traffic. If the labels do not match, the Service may have no endpoints.

### Recreating the Cluster
The lab7/scripts/create-cluster.sh script rebuilds the kind cluster, builds and loads the Docker image, and deploys the Kubernetes resources. The namespace is created first because other resources depend on it.

### Docker Image
The application uses the pinned image tag acs730-lab4:v1 instead of latest. This makes the deployed version identifiable. The image must be loaded into kind because the cluster has its own container image store.

### Kubernetes Service
The application uses NodePort on port 30080. A LoadBalancer would require a cloud load balancer integration, which this local kind cluster does not provide.

### Scaling and Recovery
I started with two replicas and scaled the Deployment to four. Kubernetes created two additional pods. When I deleted the pods, the Deployment automatically created replacements. I restored the Deployment to two replicas afterward.

### Evidence
- week09-app-response.txt
- week09-kubectl-get-all.txt
- week09-scaling.txt

## Experiments

### Experiment 1 - Pod Recovery

**Prediction:** Having two replicas should provide better availability
because another pod can continue serving traffic while one is replaced.

**What I did:** I deleted a pod while running two replicas, then repeated
the test with one replica. I checked the health endpoint 20 times during
each test.

**Observation:** With two replicas, 1 failed requests out of 20. With one replica, 4 failed requests out of 20.
Kubernetes automatically replaced the deleted pods. This demonstrated
that a Deployment maintains its requested replica count, but a single
replica provides no redundancy if that pod becomes unavailable.
I restored the Deployment to two replicas.

### Experiment 2 - ConfigMap Changes

**Prediction:** Updating a ConfigMap will not automatically change
environment variables inside containers that are already running.

**What I did:** I changed LOG_LEVEL to debug, inspected the running
container, restarted the Deployment, and checked again.

**Observation:** Initially LOG_LEVEL was `info`. Without restarting,
the container still showed `info`. After restarting the Deployment,
it showed `debug`. This demonstrated that ConfigMap-backed environment
variables are loaded when a container starts, not continuously updated.
I restored the original configuration afterward.

## Week 10 - CI/CD
To be completed in Part 2 of Lab 7.
