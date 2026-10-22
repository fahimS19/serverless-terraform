# Serverless Document Pipeline

A practical Terraform project for automatically checking uploaded document metadata and emailing the result.

**Flow:** S3 uploads → SQS → Lambda → SNS → email. Failed processing is retried and can move to an SQS dead-letter queue. Lambda logs go to CloudWatch.

## HTML guide

Open [serverless-document-pipeline.html](serverless-document-pipeline.html) after cloning or downloading this repository. It contains the problem, architecture, folder structure, copyable code, deployment commands, troubleshooting, and cleanup steps. GitHub displays HTML source; open the downloaded file in your browser.

## Project files

| File                      | Purpose                                            |
| ------------------------- | -------------------------------------------------- |
| versions.tf / provider.tf | Terraform requirements and AWS provider            |
| variables.tf / main.tf    | Inputs, account data, and naming                   |
| s3.tf                     | Private upload bucket and event notification       |
| sqs.tf                    | Processing queue, dead-letter queue, and S3 policy |
| sns.tf                    | Notification topic and email subscription          |
| iam.tf                    | Lambda execution permissions                       |
| lambda.tf                 | Function packaging, log group, and queue trigger   |
| lambda/handler.py         | Metadata checks and notification                   |
| outputs.tf                | Resource names and URLs                            |
| terraform.tfvars.example  | Example configuration                              |

## Deploy

Requires Terraform 1.6+, AWS CLI, and AWS credentials with permission to create the resources.

```bash
git clone https://github.com/akiltipu/serverless-document-pipeline.git
cd serverless-document-pipeline
cp terraform.tfvars.example terraform.tfvars
```

Edit `notification_email` in `terraform.tfvars`. The default region is `us-east-1`.

```bash
aws sts get-caller-identity
terraform init
terraform fmt -check
terraform validate
terraform plan
terraform apply
```

Confirm the SNS subscription using the email AWS sends you.

## Try it

Upload an existing PDF, JPG, or PNG of 1 byte to 5 MiB:

```bash
aws s3 cp /path/to/document.pdf "s3://$(terraform output -raw bucket_name)/uploads/document.pdf" \
  --region "$(terraform output -raw aws_region)"
```

Check the notification email and the Lambda CloudWatch logs. Upload an unsupported extension or oversized file to receive a REJECTED result. Rejection is a processed business result; technical failures are retried and may reach the dead-letter queue.

This demo checks filenames and object size only. It does not inspect document content, scan malware, or remove rejected objects. Delivery is at least once, so duplicate notifications are possible.

## Cleanup

The bucket deliberately uses `force_destroy = false`. When you are ready to delete the demo data and resources, empty **this project's bucket**, then destroy the stack:

```bash
aws s3 rm "s3://$(terraform output -raw bucket_name)" --recursive \
  --region "$(terraform output -raw aws_region)"
terraform destroy
```

AWS usage charges may apply. Keep state, credentials, and local variable files out of Git. Commit the generated `.terraform.lock.hcl` after initialization.

## Validation status

Original guide and Terraform source are preserved. Python syntax and the guide's embedded source are checked during repository preparation. Terraform validation and AWS deployment have not been run in this environment.
