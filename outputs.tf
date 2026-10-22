output "bucket_name" {
  value = aws_s3_bucket.documents.bucket
}

output "queue_url" {
  value = aws_sqs_queue.processing.url
}

output "dead_letter_queue_url" {
  value = aws_sqs_queue.dead_letter.url
}

output "lambda_function_name" {
  value = aws_lambda_function.processor.function_name
}

output "sns_topic_arn" {
  value = aws_sns_topic.notifications.arn
}

output "aws_region" {
  value = var.aws_region
}
