# Midterm Practice -- Notes

## Task 5: git hygiene

Deleting the Terraform state file and exposed credentials from the latest commit is not enough because they remain accessible in earlier Git commits, so the affected credentials must be rotated or revoked and sensitive information removed from Git history.
