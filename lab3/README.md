# Lab 3

Instructions for this section will be provided in class and on Blackboard when we reach it.

Put your work for Lab 3 in this folder.


# Lab 3 - Terraform and GitHub Actions

## Credential Model

In a real AWS environment, GitHub Actions would typically use OIDC to obtain temporary AWS credentials without storing access keys in GitHub. This is more secure because credentials are issued when needed instead of being stored as secrets.

For this lab, AWS Academy does not allow us to create the IAM resources needed for OIDC. Instead, we use temporary session credentials from Vocareum. The refresh-gha-creds.sh script adds these credentials to GitHub Actions secrets and configures the AWS region as a variable. These credentials expire when the lab session ends, limiting how long they can be used if exposed. Their AWS permissions also restrict what they can access.


## Troubleshooting

### ExpiredToken

This error happens when the temporary AWS credentials from Vocareum expire after the lab session ends. To fix it, I would start a new AWS lab session, run refresh-gha-creds.sh again to update the GitHub Actions secrets, and rerun the failed workflow. No repository changes are needed.

### Input required and not supplied: aws-region

This error happens when the AWS_REGION variable is missing from GitHub Actions. To fix it, I would rerun refresh-gha-creds.sh or set the AWS_REGION variable to us-east-1 using the GitHub CLI.

## Terraform Version

I used Terraform version 1.10.3 for this lab on both my AWS workstation and GitHub Actions.

## Experiments

### Experiment 1 - Removing the S3 Backend

**Prediction:**
If I remove the S3 backend and initialize Terraform again, I expect Terraform to switch to local state storage. A GitHub Actions runner would no longer have access to the shared state, so it could attempt to create a resource that already exists.

**Observation:**

After removing the S3 backend and running `terraform init -migrate-state`, Terraform asked if I wanted to copy the existing state locally. I selected yes, and Terraform created a local `terraform.tfstate` file containing my existing AWS resource.

**Explanation:**

This showed me why remote state is important when using GitHub Actions. Without a shared backend, the GitHub Actions runner would not have access to my workstation's local state and could try creating resources that already exist. I restored the S3 backend afterward, and Terraform confirmed there were no changes needed.

### Experiment 2 - Expired AWS Credentials

**Prediction:**

I expect the GitHub Actions deployment to fail after ending my AWS lab session because the temporary credentials will no longer be valid. I predict the workflow will fail when it tries to authenticate with AWS and return an ExpiredToken error.
