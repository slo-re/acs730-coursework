# Lab 6 - Ansible Configuration Management and Golden AMIs

## Overview

I used Terraform to create two Amazon Linux 2023 web servers. Both have the existing LabInstanceProfile attached, with HTTP allowed on port 80 and no inbound SSH rule. Ansible finds them through the Lab and Role tags instead of using a manually maintained list of IP addresses.

## Configuration and security

The GitHub Actions workflow uses AWS Systems Manager Session Manager to reach the instances. This avoids storing a long-lived SSH key in GitHub or opening port 22 for the runner. The SSM connection transfers files through the lab6 S3 bucket, which must be in the same us-east-1 region configured in Ansible.

## Idempotency

My first Ansible run configured the two servers. The next run reported changed=0 and failed=0 for both. This proves the tasks checked the current configuration and found it already matched the desired state.

I moved the tasks into a reusable webserver role with defaults, handlers and Jinja2 templates. The same role was used to configure the EC2 servers and build the golden AMI.

## Boot-to-ready comparison

| Method | Measured time |
|---|---:|
| Ansible converge-on-boot | 125 seconds |
| Golden AMI | 20 seconds |

The Ansible measurement includes replacing an EC2 instance, waiting for SSM and running the playbook until the web page responds. The golden AMI measurement includes launching a preconfigured instance until HTTP returns successfully.

The golden AMI was 105 seconds faster in my test. The main difference is that Ansible has to wait for the instance to become reachable and then configure it, whereas Packer has already done that work before the image is launched.

For an environment launching many similar servers, I would choose a golden AMI because it makes startup faster and more predictable. For a small number of servers with frequent configuration changes, Ansible convergence may be easier to maintain.

Golden AMIs still need to be rebuilt when software updates are released. Converge-on-boot depends on package downloads and configuration services being available whenever a new instance starts.

## Golden AMI cleanup

Deregistering an AMI is not enough because its underlying EBS snapshot remains stored and can continue costing money. I must record and delete the snapshot separately after deregistering the AMI.

## Experiments

### Experiment 1 - Commands and idempotency

**Prediction:** A shell command running mkdir -p would report a change every time, even if the directory already existed. Adding creates should allow Ansible to skip a command when its expected directory exists.

**Observation:** On the first run, both tasks changed on both hosts. On the second run, the unguarded shell task still changed, while the guarded task did not. I removed the test directories afterward. This showed why using modules or appropriate guards is important for idempotency.

### Experiment 2 - Fixing configuration drift

**Prediction:** If I manually changed the web page on one server, the next Ansible run would repair that server while leaving the other one unchanged.

**Observation:** After adding a temporary line to one server's HTML, Ansible changed one host and reported zero changes on the other. The following run reported changed=0 for both. This showed that the role can correct configuration drift.

## Evidence

The evidence directory contains the inventory graph, Ansible runs, experiment outputs, Packer build log, both timing measurements, and the final screenshots and teardown record.
