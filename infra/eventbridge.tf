data "aws_iam_policy_document" "scheduler_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["scheduler.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "scheduler" {
  name               = "${var.project_name}-scheduler-role"
  assume_role_policy = data.aws_iam_policy_document.scheduler_assume_role.json
}

data "aws_iam_policy_document" "scheduler_invoke_ingest" {
  statement {
    actions   = ["lambda:InvokeFunction"]
    resources = [aws_lambda_function.ingest.arn]
  }

  # Allow the scheduler to deliver failed invocations to the DLQ.
  statement {
    actions   = ["sqs:SendMessage"]
    resources = [aws_sqs_queue.dlq.arn]
  }
}

resource "aws_iam_policy" "scheduler_invoke_ingest" {
  name   = "${var.project_name}-scheduler-invoke-ingest"
  policy = data.aws_iam_policy_document.scheduler_invoke_ingest.json
}

resource "aws_iam_role_policy_attachment" "scheduler_invoke_ingest" {
  role       = aws_iam_role.scheduler.name
  policy_arn = aws_iam_policy.scheduler_invoke_ingest.arn
}

resource "aws_scheduler_schedule" "hourly_ingest" {
  name                = "${var.project_name}-hourly-ingest"
  description         = "Hourly USGS earthquake ingest trigger"
  schedule_expression = "rate(1 hour)"

  flexible_time_window {
    mode = "OFF"
  }

  target {
    arn      = aws_lambda_function.ingest.arn
    role_arn = aws_iam_role.scheduler.arn

    dead_letter_config {
      arn = aws_sqs_queue.dlq.arn
    }

    retry_policy {
      maximum_event_age_in_seconds = 3600
      maximum_retry_attempts       = 3
    }
  }
}

resource "aws_cloudwatch_event_rule" "raw_object_created" {
  name        = "${var.project_name}-raw-object-created"
  description = "Route new raw USGS S3 objects to the curate Lambda"

  event_pattern = jsonencode({
    source        = ["aws.s3"]
    "detail-type" = ["Object Created"]
    detail = {
      bucket = {
        name = [aws_s3_bucket.data.bucket]
      }
      object = {
        key = [
          {
            prefix = "raw/source=usgs/"
          }
        ]
      }
    }
  })
}

resource "aws_cloudwatch_event_target" "raw_to_curate" {
  rule      = aws_cloudwatch_event_rule.raw_object_created.name
  target_id = "curate-lambda"
  arn       = aws_lambda_function.curate.arn

  dead_letter_config {
    arn = aws_sqs_queue.dlq.arn
  }

  retry_policy {
    maximum_event_age_in_seconds = 3600
    maximum_retry_attempts       = 3
  }

  depends_on = [aws_lambda_permission.allow_s3_curate]
}
