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


## Week 10 - CI/CD to Kubernetes

### Why GitHub-hosted runners cannot reach the cluster

The kind Kubernetes cluster runs locally through Docker on my EC2 workstation. Its API server is not publicly accessible, so a GitHub-hosted runner cannot connect to it. This is a networking limitation rather than an authentication problem. A token would not solve it. My Lab 7 CI workflow can use ubuntu-latest because it only validates files, but the deployment workflow needs the self-hosted runner on the workstation.

### Self-hosted runner security and residual risk

A self-hosted runner executes workflow commands on my workstation. If I allowed pull requests from forks to trigger deployment, an external contributor could potentially execute code on the workstation and access its AWS instance role and local resources.

I limited deployment triggers to pushes to main, with no pull_request trigger. I also used a namespace-scoped Kubernetes ServiceAccount instead of giving the deployment workflow cluster-admin access. Fork pull request approval is an additional repository-level protection. At the end of this lab, I remove the runner registration and service.

**Residual risk:** Anyone able to push malicious workflow code to main, including someone who compromises my GitHub account, could still execute commands as ec2-user on the workstation. That account has Docker access and an AWS instance profile. A separate disposable runner would reduce the impact.

### Kubernetes ServiceAccount permissions

The deployment account can patch Deployments but cannot delete Deployments, read Secrets, create namespaces or delete nodes. The authorization tests returned yes, no, no, no and no in that order.

The account can update ConfigMaps because application configuration changes during deployment. It cannot read Secrets because the pipeline should not need access to stored credentials. The application can still receive APP_TOKEN because Kubernetes resolves the Secret reference for the pod.

### Deployment rollout gate

The workflow builds the Docker image, loads it into kind, applies the manifests and updates the Deployment image to a tag based on the Git commit. Then kubectl rollout status runs as a separate step.

This matters because kubectl set image can succeed before any new pod becomes healthy. Without the rollout status step, the pipeline could incorrectly report success even if the new deployment never became ready.

### Failed rollout and recovery

I deliberately changed the readiness probe from /healthz to /not-a-real-path. The new pods could start but did not become ready. GitHub Actions failed specifically at the rollout verification step after waiting for the deployment.

I used kubectl rollout undo through the restricted ServiceAccount to restore the previous healthy revision. The readiness probe returned to /healthz, and the application continued responding. I also committed the corrected manifest to GitHub because rolling back the cluster does not fix the version stored in the repository. The recovery workflow completed successfully.

### Week 10 evidence

- Successful workflow: 44936733589
- Intentionally failed rollout: 44936534069
- Rollout failure logs: week10-deploy-red.txt
- Rollback evidence: week10-rollout-undo.txt

The two experiments completed in Week 9 remain documented earlier in this README.
