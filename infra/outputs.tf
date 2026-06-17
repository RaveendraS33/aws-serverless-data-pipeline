output "bucket_name" {
  value = aws_s3_bucket.data.bucket
}

output "glue_database" {
  value = aws_glue_catalog_database.lakehouse.name
}

output "glue_table" {
  value = aws_glue_catalog_table.earthquakes.name
}

output "athena_workgroup" {
  value = aws_athena_workgroup.portfolio.name
}

output "region" {
  value = var.aws_region
}
