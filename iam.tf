data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda" {
  name               = "${local.prefix}-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

resource "aws_iam_role_policy_attachment" "basic_logs" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Lambda's SQS event source mapping requires read/delete permissions.
data "aws_iam_policy_document" "lambda_access" {
  statement {
    sid = "ReadQueue"
    actions = [
      "sqs:ReceiveMessage", "sqs:DeleteMessage",
      "sqs:GetQueueAttributes"
    ]
    resources = [aws_sqs_queue.processing.arn]
  }

  statement {
    sid       = "ReadUploadedObjectMetadata"
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.documents.arn}/uploads/*"]
  }

  statement {
    sid       = "PublishNotification"
    actions   = ["sns:Publish"]
    resources = [aws_sns_topic.notifications.arn]
  }
}

resource "aws_iam_role_policy" "lambda_access" {
  name   = "${local.prefix}-lambda-access"
  role   = aws_iam_role.lambda.id
  policy = data.aws_iam_policy_document.lambda_access.json
}
