data "archive_file" "ingest_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../src"
  output_path = "${path.module}/ingest.zip"
}

data "archive_file" "curate_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../src"
  output_path = "${path.module}/curate.zip"
}

resource "aws_lambda_function" "ingest" {
  function_name    = "${var.project_name}-ingest"
  role             = aws_iam_role.ingest_lambda.arn
  handler          = "ingest.handler.lambda_handler"
  runtime          = "python3.11"
  filename         = data.archive_file.ingest_zip.output_path
  source_code_hash = data.archive_file.ingest_zip.output_base64sha256
  timeout          = 60
  memory_size      = 256

  environment {
    variables = {
      DATA_BUCKET = aws_s3_bucket.data.bucket
    }
  }
}

resource "aws_lambda_function" "curate" {
  function_name    = "${var.project_name}-curate"
  role             = aws_iam_role.curate_lambda.arn
  handler          = "curate.handler.lambda_handler"
  runtime          = "python3.11"
  filename         = data.archive_file.curate_zip.output_path
  source_code_hash = data.archive_file.curate_zip.output_base64sha256
  timeout          = 120
  memory_size      = 1024
  layers           = [var.awswrangler_layer_arn]

  environment {
    variables = {
      DATA_BUCKET = aws_s3_bucket.data.bucket
    }
  }
}

resource "aws_lambda_permission" "allow_s3_curate" {
  statement_id  = "AllowS3InvokeCurate"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.curate.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.data.arn
}

resource "aws_s3_bucket_notification" "raw_to_curate" {
  bucket = aws_s3_bucket.data.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.curate.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "raw/source=usgs/"
    filter_suffix       = ".geojson"
  }

  depends_on = [aws_lambda_permission.allow_s3_curate]
}
