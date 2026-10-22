resource "aws_sqs_queue" "dead_letter" {
  name                      = "${local.prefix}-dlq"
  message_retention_seconds = 1209600 # 14 days
}

resource "aws_sqs_queue" "processing" {
  name                       = "${local.prefix}-queue"
  visibility_timeout_seconds = 60
  message_retention_seconds  = 345600 # 4 days

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dead_letter.arn
    maxReceiveCount     = 3
  })
}

# S3 publishes event notifications to the queue.
data "aws_iam_policy_document" "allow_s3_queue" {
  statement {
    sid     = "AllowS3Events"
    effect  = "Allow"
    actions = ["sqs:SendMessage"]
    resources = [aws_sqs_queue.processing.arn]

    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [aws_s3_bucket.documents.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }
}

resource "aws_sqs_queue_policy" "allow_s3" {
  queue_url = aws_sqs_queue.processing.id
  policy    = data.aws_iam_policy_document.allow_s3_queue.json
}
