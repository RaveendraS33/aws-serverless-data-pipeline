resource "aws_athena_named_query" "recent_quakes" {
  name      = "01_recent_quakes"
  database  = aws_glue_catalog_database.lakehouse.name
  workgroup = aws_athena_workgroup.portfolio.name
  query     = file("${path.module}/../queries/01_recent_quakes.sql")
}

resource "aws_athena_named_query" "daily_counts_by_region" {
  name      = "02_daily_counts_by_region"
  database  = aws_glue_catalog_database.lakehouse.name
  workgroup = aws_athena_workgroup.portfolio.name
  query     = file("${path.module}/../queries/02_daily_counts_by_region.sql")
}

resource "aws_athena_named_query" "magnitude_distribution" {
  name      = "03_magnitude_distribution"
  database  = aws_glue_catalog_database.lakehouse.name
  workgroup = aws_athena_workgroup.portfolio.name
  query     = file("${path.module}/../queries/03_magnitude_distribution.sql")
}
