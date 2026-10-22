data "archive_file" "processor" {
  type        = "zip"
  source_file = "${path.module}/lambda/handler.py"
  output_path = "${path.module}/processor.zip"
}

resource "aws_cloudwatch_log_group" "processor" {
  name              = "/aws/lambda/${local.prefix}-processor"
  retention_in_days = 7
}

resource "aws_lambda_function" "processor" {
  function_name    = "${local.prefix}-processor"
  filename         = data.archive_file.processor.output_path
  source_code_hash = data.archive_file.processor.output_base64sha256
  handler          = "handler.lambda_handler"
  runtime          = "python3.12"
  role             = aws_iam_role.lambda.arn
  timeout          = 10
  memory_size      = 128

  environment {
    variables = {
      TOPIC_ARN = aws_sns_topic.notifications.arn
      MAX_BYTES = "5242880" # 5 MiB
    }
  }

  depends_on = [
    aws_cloudwatch_log_group.processor,
    aws_iam_role_policy_attachment.basic_logs,
    aws_iam_role_policy.lambda_access
  ]
}

resource "aws_lambda_event_source_mapping" "sqs" {
  event_source_arn = aws_sqs_queue.processing.arn
  function_name    = aws_lambda_function.processor.arn
  batch_size       = 1
  enabled          = true
}
