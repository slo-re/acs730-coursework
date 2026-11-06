# ACS730 Lab 5 — Terraform and LocalStack

## What I built

This lab uses Terraform to define a VPC, two public subnets, an internet gateway, a route table, route table associations, a web security group, an EC2 instance, and an optional S3 bucket.

The same Terraform configuration can target AWS or LocalStack through the use_localstack variable. I tested the infrastructure against LocalStack to avoid creating billable AWS resources.

The configuration uses data sources to look up AWS information, for_each to create subnets, a dynamic block for security group rules, and user_data to configure an Nginx web server. Dependencies between resources are defined using references, with an explicit depends_on for routing.

## Why for_each here and count there

I used for_each for subnets because each subnet has a stable key. Adding subnet "c" would create a new subnet without changing the existing "a" and "b" subnets. Removing a subnet only affects the corresponding key.

With count, resources are identified by numbered indexes. Removing an item from the middle can shift the indexes and cause Terraform to replace resources unnecessarily.

I used count for the optional S3 bucket because it is controlled by a simple true/false setting. When disabled, Terraform creates no bucket. When enabled, it creates one. The one() function allows the output to return null when the bucket does not exist.

## Why not plan and apply against real AWS on every pull request

Running Terraform apply against real AWS for every pull request would increase costs and introduce unnecessary risks. In AWS Academy, students share a limited lab budget, and repeated deployments would consume credits.

Real AWS deployment also requires credentials. Academy sessions expire, so automated workflows could fail because credentials expired rather than because the Terraform code is incorrect.

Real deployments are slower and can encounter API limits, resource naming conflicts, and account restrictions.

LocalStack avoids those costs and lets CI verify that the configuration can be planned and applied. However, passing LocalStack tests does not prove that real AWS permissions are correct or that the EC2 user_data script works, because LocalStack does not actually boot the instance.

A controlled real AWS test would be more appropriate after the configuration has passed the earlier checks.

## Experiments



### Experiment 1 — Removing depends_on

Prediction: Removing the explicit depends_on should not change the number of resources in the plan, since the same resources are still defined.

Removing the dependency does change the ordering Terraform can use during deployment. The EC2 instance references its subnet and security group, but those references do not guarantee that the internet route is ready before the instance starts.

LocalStack may not reveal this issue because it simulates EC2 rather than booting a real virtual machine. Both plans showed 10 resources to add, with no changes or destructions. I restored depends_on afterward.


### Experiment 2 — Breaking Terraform formatting

Prediction: Incorrect indentation should cause the fmt and validate CI job to fail at the formatting step, even though Terraform can still understand the configuration.

Because the LocalStack job depends on the first job using needs, it should be skipped instead of running unnecessarily.


### Final Experiment 2 Result

The formatting check failed as predicted while terraform validate
succeeded locally. In GitHub Actions, the formatting gate failed,
so the LocalStack deployment job was skipped. After the test,
I restored the correct Terraform formatting.
