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
  }
}
