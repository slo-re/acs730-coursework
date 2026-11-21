# Assignment 1 - Multi-Environment Infrastructure Deployment with Terraform

## Introduction

The goal of this assignment was to extend my Terraform and GitHub Actions work into a multi-environment deployment. I used one reusable Terraform module to deploy dev, staging and prod instead of maintaining three separate copies of the infrastructure. I also configured a deployment pipeline where staging deploys automatically and production requires approval.

The infrastructure runs in my AWS Academy account in `us-east-1`. I used the existing course repository and S3 Terraform state bucket.

## Terraform Design

I refactored my earlier Lab 5 Terraform configuration into `terraform/modules/infrastructure/`. The module manages the VPC, public subnets, internet gateway, routing, security group, EC2 web server and CloudWatch CPU alarm.

Each environment calls the same module but passes its own environment name, network CIDRs and other settings. The module exposes outputs such as the VPC ID, web server address, alarm name and SSM parameter metadata.

The three environments use separate backend keys in the existing S3 bucket:

- `assignment1/dev/terraform.tfstate`
- `assignment1/staging/terraform.tfstate`
- `assignment1/prod/terraform.tfstate`

This is important because Terraform must not confuse resources belonging to different environments. If staging and production shared a state key, one deployment could accidentally modify or destroy another environment's resources.

The deployment uses a `t3.micro` EC2 instance per environment to keep AWS Academy costs low. The application uses HTTP on port 80. SSH access is not opened to the public internet.

## GitHub Environments and Deployment

The workflow is `.github/workflows/assignment1-deploy.yml`.

A merge to `main` automatically starts the staging job. Production depends on staging and uses the protected `prod` GitHub Environment, which requires reviewer approval. The production environment also has a deployment branch policy that allows only `main`.

I tested this by merging pull request #15. Staging succeeded without manual approval. The production job then waited until I reviewed and approved it. After approval, the production Terraform apply completed successfully.

The deployment evidence includes both apply logs and screenshots from before and after the production approval.

The three AWS credential secrets were moved from repository scope to the staging and production environments. The repository-level copies were deleted. During each AWS Academy session, I refresh the temporary credentials with:

```bash
./scripts/refresh-gha-creds.sh slo-re/acs730-coursework staging prod
```

This lab uses temporary AWS Academy credentials because the Academy account restricts IAM configuration. In a regular AWS account, I would prefer OIDC federation instead of passing AWS keys and a session token through GitHub secrets.

## Production OIDC Trust Policy

In a regular AWS account, I would configure a production IAM role with this trust policy:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::071894848660:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com",
          "token.actions.githubusercontent.com:sub": "repo:slo-re/acs730-coursework:environment:prod"
        }
      }
    }
  ]
}
```

The federated principal identifies the GitHub Actions OIDC provider registered in AWS. AWS would only accept identity tokens from that trusted provider.

The `aud` condition requires the token to be intended for AWS Security Token Service. This prevents a token issued for a different audience from being accepted for this role.

The `sub` condition limits the role to the `prod` environment of my specific GitHub repository. A workflow running under another repository or under staging cannot use the same role. A broad condition such as `repo:slo-re/acs730-coursework:*` would also include workflows running in other contexts, increasing the risk of unauthorized production access.

The environment branch policy is also important: the OIDC environment claim alone does not prove the code came from `main`. GitHub's production deployment branch policy restricts which branch can use the environment, while its reviewer requirement controls when deployment is allowed.

I did not deploy this IAM trust policy because the AWS Academy Learner Lab restricts IAM changes. The actual deployment uses session-scoped credentials. For a company, I would also require approval by a different team member rather than allowing self-approval.

## Application Secret Management

I created a placeholder application secret for each environment in AWS Systems Manager Parameter Store using the `SecureString` type.

For example, the creation command has this form:

```bash
aws ssm put-parameter \
  --name "/acs730/assignment1/dev/app-secret" \
  --type SecureString \
  --value "<generated-placeholder-value>" \
  --region us-east-1
```

I used a generated value rather than saving a real password or hardcoding it in Terraform. Each environment has its own parameter path.

Terraform reads the existing parameter through a `data "aws_ssm_parameter"` block. It does not create the same parameter as a Terraform resource. This avoids a dependency problem when Terraform needs to read a parameter that has not been created yet.

I only expose the parameter name and version as Terraform outputs, not the secret value. Sensitive values read by Terraform can still be retained in state, so the S3 backend must remain protected and state files must not be committed to Git.

## CloudWatch Monitoring

The Terraform module creates an alarm on the EC2 `CPUUtilization` metric for each environment. The alarm uses a five-minute average and an 80% threshold. One evaluation period above the threshold is enough to enter the alarm state.

This provides basic monitoring of an actual deployed resource. CPU utilization is a suitable metric for this assignment because an idle EC2 instance still produces CPU measurements.

I verified that the dev, staging and production alarms had evaluated and were showing `OK`, rather than remaining at `INSUFFICIENT_DATA`. The JSON output and AWS Console screenshot are saved in the evidence folder.

## Recommendation - GitHub Actions or an AWS-Native Pipeline?

For a team fully committed to AWS with no plans to use another cloud provider, I would recommend **an AWS-native pipeline using CodePipeline and CodeBuild**, with manual approval before production. I would keep GitHub as the source code repository if the team already uses it.

My first reason is identity and access management. In this assignment, GitHub Actions needed temporary AWS Academy credentials stored as environment secrets. A real GitHub deployment could use OIDC, which is much safer than storing long-lived keys, but it still requires configuring trust between GitHub and AWS. An AWS-native pipeline can use IAM roles directly for its services and stages. That fits naturally with an organization already managing access through AWS IAM.

Second, I would consider network access and runner management. GitHub-hosted runners worked here because the deployment only needed to contact public AWS APIs. A larger application might require deployment to private resources inside a VPC. That could require private connectivity or a self-hosted GitHub runner, which the team would need to secure, patch and maintain. CodeBuild supports running builds within an AWS VPC, avoiding the need to maintain a separate self-hosted runner for this situation.

Third, AWS provides integrated deployment and approval services. CodePipeline can connect the source, build and deployment stages, while a manual approval action can stop a production release until someone authorizes it. CloudWatch can monitor the infrastructure and pipeline activity. This keeps more of the operational controls within the same AWS environment.

There are tradeoffs. Our team already knows GitHub Actions from previous labs, and its YAML workflows are straightforward to review beside the code. GitHub-hosted runners are also convenient because we do not have to manage their operating systems. Moving to CodePipeline and CodeBuild would require additional setup, training and AWS service costs. The exact cost should be compared using expected build minutes, storage and the number of pipeline executions rather than assuming one option is always cheaper.

Even with those disadvantages, I would choose AWS-native CI/CD for this specific AWS-only team. Centralized IAM, easier integration with private AWS networking and AWS-managed execution are more valuable in the long term than maintaining a deployment setup designed to work across many platforms. If the organization later adopted multiple cloud providers, I would reconsider GitHub Actions because it offers more portability.

## Cleanup and Conclusion

I completed the assignment by validating the three Terraform environments, verifying their separate state files and collecting evidence of the successful staging and production deployments. After saving the deployment, SSM and CloudWatch evidence, I destroyed the temporary AWS infrastructure to avoid unnecessary Academy costs.

This assignment showed why a multi-environment pipeline needs more than reusable Terraform code. Separate state files prevent environments from interfering with each other, environment-scoped credentials limit access, and production approvals add a checkpoint before changes reach production. I would improve this design further in a real organization by using AWS OIDC federation, independent production reviewers and additional monitoring.

## References

- GitHub Docs, *Configuring OpenID Connect in Amazon Web Services*: https://docs.github.com/en/actions/how-tos/secure-your-work/security-harden-deployments/oidc-in-aws
- AWS Documentation, *Create a role for OpenID Connect federation*: https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_create_for-idp_oidc.html
- AWS Documentation, *Using Amazon CloudWatch alarms*: https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/CloudWatch_Alarms.html
