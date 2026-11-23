# Assignment 2 - Configuration Management Automation with Ansible and Packer

## Introduction

The purpose of this assignment was to compare two ways of preparing an AWS EC2 web server. I used Terraform with Ansible to configure a server after provisioning, then used Packer to build a golden AMI containing the same configuration before launch. I reused my Lab 6 webserver role and tested both methods in AWS Academy. I also integrated Ansible into GitHub Actions and measured how quickly each approach served a working web page.

## Terraform, Dynamic Inventory and Ansible

Terraform provisioned an Amazon Linux 2023 EC2 instance with the `LabInstanceProfile` instance profile. The instance was discovered automatically by Ansible using the `amazon.aws.aws_ec2` inventory plugin and Terraform-created tags. I did not maintain a separate list of IP addresses or instance IDs.

My configuration is packaged in the `webserver` Ansible role. It contains tasks, defaults, handlers and Jinja2 templates. The role creates the service account and application directory, installs the required packages, renders the HTML page and systemd service file, and ensures the web server is enabled and running. The HTML template displays information such as the hostname, private IP and build type.

I verified idempotency with two consecutive runs. The first run made six changes with no failures. Without changing the host between runs, the second completed with **changed=0, unreachable=0 and failed=0**. This demonstrates that Ansible can check and maintain the desired state without unnecessarily reapplying the configuration. Both runs and the rendered template output are saved in the evidence folder.

## GitHub Actions Integration and Security

I added `.github/workflows/assignment2-deploy.yml`, which uses Terraform to provision the infrastructure and runs **Ansible converge immediately after Terraform apply**. The GitHub Actions deployment completed successfully in run `45103312970`, including the final HTTP verification.

I chose the AWS Systems Manager connection method instead of SSH. The `community.aws.aws_ssm` connection plugin uses the temporary AWS Academy credentials from the `staging` GitHub Environment and the existing S3 state bucket for file transfer. This avoids opening inbound port 22 to the internet and avoids storing a long-lived SSH private key in GitHub. The pipeline also uses dynamic inventory so a replacement EC2 instance can be discovered by tag.

## Packer Golden AMI

I used Packer with the same Ansible webserver role to build a golden AMI. Rather than maintaining a separate installation script, the AMI and post-provisioning approach share the same configuration tasks and templates.

The Packer build completed in **3 minutes 37 seconds** and produced AMI `ami-095bbfc6cc65eda87`. I verified the image was available and saved its AWS description and a console screenshot. Packer removed its temporary build instance after completing the image.

## Boot-to-Ready Measurements

For a consistent comparison, both methods used `t3.micro` instances, the same subnet and security group, and the same measurement boundaries.

**Start:** AWS EC2 instance `LaunchTime`.

**End:** The first observed successful HTTP response containing the expected Assignment 2 web page.

| Method | Boot-to-ready |
|---|---:|
| Terraform + Ansible over SSM | 60 seconds |
| Packer golden AMI | 19 seconds |
| Difference | 41 seconds |

The golden AMI was approximately **3.2 times as fast** to become ready in this test, saving **41 seconds**. These are measurements from one launch per method, so they demonstrate this test rather than guaranteeing the same performance for every launch. The Ansible measurement includes time spent waiting for SSM and completing configuration, while the golden AMI starts with the web server already installed.

## Comparison and Recommendation

For a team deploying dozens of times per day, I would prefer **Packer golden AMIs**, particularly when launching new instances frequently or using an Auto Scaling group. In my test, a golden AMI served the web page after 19 seconds compared with 60 seconds using Ansible. Faster readiness becomes valuable when replacing failed instances or responding to increased traffic. New instances also begin from a consistent, tested image instead of downloading and configuring packages during every launch.

The trade-off is that preparing the AMI takes time. My Packer build required 3 minutes 37 seconds before any server could launch from it. The configuration work did not disappear; it moved into the image-building stage. Updates also require building, testing and distributing a new image, followed by replacing or updating existing instances. A stale image can contain outdated packages if the build pipeline is not maintained. I would therefore automate image builds, vulnerability scanning and controlled rollouts for a frequently deploying team.

For a team deploying only once a month with a small number of long-lived servers, I would usually recommend **Terraform plus Ansible**. The 60-second readiness time is less significant when deployments are infrequent. Ansible is convenient for updating existing machines without rebuilding and replacing their AMIs. Its idempotency also makes it useful for correcting configuration drift and applying changes consistently.

Ansible has its own risks. It depends on working access to the instances through SSM, and package repositories or external dependencies can change between runs. If a package version is not pinned, two deployments might produce different results. The golden AMI reduces that variability for newly launched instances, but does not automatically patch running servers.

The best choice depends on deployment frequency, startup requirements and maintenance practices. For frequent scaling and rapid replacement, I would invest in tested golden images. For occasional configuration changes on existing servers, Ansible would likely be simpler to maintain. Both approaches can share the same Ansible role, as they did in this assignment, reducing duplicated configuration work.

## Conclusion

This assignment showed that both methods can create the same functioning web server, but they perform configuration at different stages. The golden AMI reached readiness faster in my measurement, while Ansible provided a repeatable and idempotent way to manage configuration after provisioning. I would choose golden AMIs for frequent instance launches and Ansible for occasional configuration updates. After collecting the required evidence, I destroyed the temporary instances, deregistered the AMI and removed its snapshot to conserve AWS Academy credits.

## Evidence

The `evidence/` folder contains the dynamic inventory graph, role structure, rendered template, two idempotency runs, successful pipeline screenshot, Packer build log, AMI description and both boot-to-ready measurements.
