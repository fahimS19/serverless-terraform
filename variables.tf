variable "aws_region" {
  description = "AWS Region used by all services"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Short, lowercase prefix used for resource names"
  type        = string
  default     = "document-pipeline"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "fahim"
}

variable "notification_email" {
  description = "Email address that will confirm the SNS subscription"
  type        = string
}
