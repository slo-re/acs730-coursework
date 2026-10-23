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

