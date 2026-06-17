variable "project_name" {
  type    = string
  default = "aws-serverless-data-pipeline"
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "budget_email" {
  description = "Email address for AWS Budget alerts. Required before deploying real AWS resources."
  type        = string
  default     = ""
}

variable "bucket_name" {
  description = "Globally unique S3 bucket name. Leave empty to derive one from account and region."
  type        = string
  default     = ""
}

variable "awswrangler_layer_arn" {
  description = "AWS SDK for pandas Lambda layer ARN for Python 3.11 in us-east-1. Checked from official docs."
  type        = string
  default     = "arn:aws:lambda:us-east-1:336392948345:layer:AWSSDKPandas-Python311:31"
}

variable "athena_scan_cap_bytes" {
  type    = number
  default = 104857600
}
