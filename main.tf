data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

locals {
  prefix = "${var.project_name}-${var.environment}"
  # Account ID makes the bucket name globally unique in typical demo setups.
  bucket_name = "${local.prefix}-${data.aws_caller_identity.current.account_id}-${var.aws_region}"
}
