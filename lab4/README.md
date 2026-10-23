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


