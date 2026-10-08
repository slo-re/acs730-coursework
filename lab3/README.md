# Lab 3

Instructions for this section will be provided in class and on Blackboard when we reach it.

Put your work for Lab 3 in this folder.


# Lab 3 - Terraform and GitHub Actions

## Credential Model

In a real AWS environment, GitHub Actions would typically use OIDC to obtain temporary AWS credentials without storing access keys in GitHub. This is more secure because credentials are issued when needed instead of being stored as secrets.

For this lab, AWS Academy does not allow us to create the IAM resources needed for OIDC. Instead, we use temporary session credentials from Vocareum. The refresh-gha-creds.sh script adds these credentials to GitHub Actions secrets and configures the AWS region as a variable. These credentials expire when the lab session ends, limiting how long they can be used if exposed. Their AWS permissions also restrict what they can access.
