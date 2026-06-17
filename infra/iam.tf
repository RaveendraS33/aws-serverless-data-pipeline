data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ingest_lambda" {
  name               = "${var.project_name}-ingest-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

resource "aws_iam_role" "curate_lambda" {
  name               = "${var.project_name}-curate-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

resource "aws_iam_role_policy_attachment" "ingest_basic" {
  role       = aws_iam_role.ingest_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "curate_basic" {
  role       = aws_iam_role.curate_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

data "aws_iam_policy_document" "ingest_access" {
  statement {
    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.data.arn}/raw/*"]
  }
}

data "aws_iam_policy_document" "curate_access" {
  statement {
    actions = ["s3:GetObject"]
    resources = [
      "${aws_s3_bucket.data.arn}/raw/*",
      "${aws_s3_bucket.data.arn}/curated/*",
    ]
  }

  statement {
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.data.arn]
  }

  statement {
    actions = [
      "s3:AbortMultipartUpload",
      "s3:DeleteObject",
      "s3:ListMultipartUploadParts",
      "s3:PutObject",
    ]
    resources = ["${aws_s3_bucket.data.arn}/curated/*"]
  }
}

resource "aws_iam_policy" "ingest_access" {
  name   = "${var.project_name}-ingest-access"
  policy = data.aws_iam_policy_document.ingest_access.json
}

resource "aws_iam_policy" "curate_access" {
  name   = "${var.project_name}-curate-access"
  policy = data.aws_iam_policy_document.curate_access.json
}

resource "aws_iam_role_policy_attachment" "ingest_access" {
  role       = aws_iam_role.ingest_lambda.name
  policy_arn = aws_iam_policy.ingest_access.arn
}

resource "aws_iam_role_policy_attachment" "curate_access" {
  role       = aws_iam_role.curate_lambda.name
  policy_arn = aws_iam_policy.curate_access.arn
}
