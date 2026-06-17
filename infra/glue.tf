resource "aws_glue_catalog_database" "lakehouse" {
  name = replace(var.project_name, "-", "_")
}

resource "aws_glue_catalog_table" "earthquakes" {
  name          = "earthquakes"
  database_name = aws_glue_catalog_database.lakehouse.name
  table_type    = "EXTERNAL_TABLE"

  parameters = {
    "classification"              = "parquet"
    "projection.enabled"          = "true"
    "projection.dt.type"          = "date"
    "projection.dt.range"         = "2024-01-01,NOW"
    "projection.dt.format"        = "yyyy-MM-dd"
    "projection.dt.interval"      = "1"
    "projection.dt.interval.unit" = "DAYS"
    "storage.location.template"   = "s3://${aws_s3_bucket.data.bucket}/curated/earthquakes/dt=$${dt}/"
    "EXTERNAL"                    = "TRUE"
    "parquet.compression"         = "SNAPPY"
  }

  partition_keys {
    name = "dt"
    type = "string"
  }

  storage_descriptor {
    location      = "s3://${aws_s3_bucket.data.bucket}/curated/earthquakes/"
    input_format  = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetOutputFormat"

    ser_de_info {
      serialization_library = "org.apache.hadoop.hive.ql.io.parquet.serde.ParquetHiveSerDe"
    }

    columns {
      name = "event_id"
      type = "string"
    }
    columns {
      name = "event_time"
      type = "timestamp"
    }
    columns {
      name = "updated_time"
      type = "timestamp"
    }
    columns {
      name = "mag"
      type = "double"
    }
    columns {
      name = "magtype"
      type = "string"
    }
    columns {
      name = "place"
      type = "string"
    }
    columns {
      name = "longitude"
      type = "double"
    }
    columns {
      name = "latitude"
      type = "double"
    }
    columns {
      name = "depth_km"
      type = "double"
    }
    columns {
      name = "type"
      type = "string"
    }
    columns {
      name = "tsunami"
      type = "int"
    }
    columns {
      name = "sig"
      type = "int"
    }
    columns {
      name = "alert"
      type = "string"
    }
    columns {
      name = "status"
      type = "string"
    }
    columns {
      name = "url"
      type = "string"
    }
    columns {
      name = "net"
      type = "string"
    }
  }
}
