# Lab 4

Instructions for this section will be provided in class and on Blackboard when we reach it.

Put your work for Lab 4 in this folder.

## Week 4 - Docker Fundamentals

### Building and Running the Application

Build: `docker build -t acs730-lab4:slim .`

Run: `docker run -d --name lab4 -p 8000:8000 acs730-lab4:slim`

Test: `curl http://localhost:8000/healthz`

Cleanup: `docker rm -f lab4`

The /healthz endpoint returns JSON confirming the application is healthy.

### Docker Image Comparison

| Measurement | Naive | Optimized |
|---|---|---|
| Base image | python:latest | python:3.12-slim-bookworm |
| Image size | 1.15 GB | 130 MB |
| Rebuild time | 5.990 seconds | 0.669 seconds |
| Runtime user | root | appuser |

The initial naive image build took 26.425 seconds.

### Analysis

- Image size: The optimized image is approximately 89% smaller. Most of the size reduction comes from using the smaller Python slim base image instead of the full Python image.

- Docker caching: The naive Dockerfile copies application code before installing dependencies. A code change therefore invalidates the pip installation layer. The optimized Dockerfile installs dependencies first, allowing that layer to remain cached when only application code changes.

- .dockerignore: Excludes unnecessary files such as screenshots, Markdown files, Dockerfiles, and Python cache directories. This reduces the build context and prevents unnecessary files from being copied.

- Security: The optimized image runs as a non-root user called appuser, while the naive image runs as root.



## Week 5 - CI Cache Measurements

I measured three GitHub Actions runs: a baseline without caching,
the first run with caching enabled, and a run that restored the caches.

| Step | Baseline | Cache miss | Cache hit |
|---|---|---|---|
| Python 3.11 dependencies | 3s | 3s | 2s |
| Python 3.12 dependencies | 5s | 3s | 2s |
| Docker build | 7s | 13s | 5s |
| Full workflow | 61s | 69s | 75s |

### Cache Analysis

Pip cache: Both Python versions successfully restored their pip
caches on the third run. Installation improved to 2 seconds.
The improvement was modest because the dependencies are small,
but caching could become more useful as the project grows.

Docker layer cache: The build step took 13 seconds on the cache-miss
run and 5 seconds on the cache-hit run. The logs confirmed that
Docker reused its dependency installation layer. This is useful
for avoiding repeated dependency installation.

Overall verdict: Both caches worked, but the full workflow increased
from 61 seconds without caching to 75 seconds with a cache hit.
For this small application, the added caching overhead and
differences in runner execution mean caching did not improve
the overall pipeline time in these measurements.

GitHub Actions runs used:
- Baseline: 39875862912
- Cache miss: 39877080302
- Cache hit: 39877772001


## Experiments

### Experiment 1 - Removing .dockerignore

Prediction: Removing .dockerignore will increase the Docker build
context because more files will be sent to Docker. However, I expect
the optimized image size to remain almost unchanged because the
Dockerfile only copies requirements.txt and app.py.


Observation: With .dockerignore, the application build context
transferred 510 bytes. Without it, the context transferred only
181 bytes. Both builds produced the same 130 MB image.

Explanation: My prediction was not supported by this test.
Docker BuildKit can optimize context transfers based on which
files the Dockerfile actually needs. Since my optimized Dockerfile
copies only requirements.txt and app.py, removing .dockerignore
did not increase the final image size. The ignore file is still
useful for larger projects and Dockerfiles that copy entire directories.


### Experiment 2 - Changing Docker Layer Order

Prediction: Moving COPY app.py before the dependency installation
will make rebuilding slower after application code changes.
Docker will invalidate the dependency installation layer,
forcing pip install to run again even though requirements.txt
has not changed.


Observation: The optimized Dockerfile rebuilt in 0.651 seconds,
while the inefficient Dockerfile took 6.736 seconds. The optimized
build reused the cached pip installation layer, whereas the
inefficient build ran pip install again.

Explanation: My prediction was correct. Docker caches each
instruction as a layer. When COPY app.py comes before pip install,
changing the application invalidates the layers that follow it.
By installing dependencies before copying application code, Docker
can reuse the dependency layer when requirements.txt has not changed.
This made the optimized rebuild approximately 10 times faster.

## GitHub Actions vs AWS-Native CI/CD

For this project, I would recommend GitHub Actions because the
source code is already hosted on GitHub, and the workflows can
build, test, and publish Docker images without requiring AWS
credentials.

The AWS-native alternative would use CodePipeline to coordinate
pipeline stages, CodeBuild to run builds and tests, and Amazon ECR
to store container images instead of GHCR.

GitHub Actions uses GitHub-hosted runners and a GITHUB_TOKEN with
permissions controlled by the workflow. The AWS-native approach
would use CodeBuild environments and IAM roles to access AWS
services such as ECR.

In our AWS Academy environment, IAM permissions are restricted,
which makes setting up some AWS-native deployment components more
difficult. GitHub Actions was easier to implement for this lab
because Docker builds and GHCR publishing did not require temporary
AWS Academy credentials.

For a production application hosted entirely in AWS, I would also
consider CodePipeline, CodeBuild, and ECR because of their direct
integration with AWS services and IAM.


## SHA Tagging and Reusable CI/CD Components

### Why SHA Tags Instead of latest?

I used commit SHA tags for GHCR images because they identify
the specific code version used to build each image. Unlike
latest, which can point to a different image after each push,
SHA tags make it easier to trace deployments, reproduce builds,
and roll back to an earlier version.

### Composite Action vs Reusable Workflow

I used a composite action for Python dependency setup because
these steps need to run within each test job on the same runner.

I used a reusable workflow for the Docker image build because
it represents an entire job with its own runner and permissions.
This also allows package publishing permissions to be limited
to the appropriate build job rather than granted to test jobs.
