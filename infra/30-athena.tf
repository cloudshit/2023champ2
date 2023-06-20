resource "aws_glue_catalog_database" "myservice_athena_db" {
  name = "default"
}

resource "aws_glue_catalog_table" "source" {
 name          = "skills_source"
 database_name = aws_glue_catalog_database.myservice_athena_db.name
 description   = "Table containing the results stored in S3 as source"


 table_type = "EXTERNAL_TABLE"


 storage_descriptor {
   location      = "s3://${aws_s3_bucket.bucket.bucket}/source"
   input_format  = "org.apache.hadoop.mapred.TextInputFormat"
   output_format = "org.apache.hadoop.hive.ql.io.IgnoreKeyTextOutputFormat"


   ser_de_info {
     name                  = "s3-stream"
     serialization_library = "org.openx.data.jsonserde.JsonSerDe"


     parameters = {
       "ignore.malformed.json" = "TRUE"
       "dots.in.keys"          = "FALSE"
       "case.insensitive"      = "TRUE"
       "mapping"               = "TRUE"
     }
   }

  columns {
    name = "date"
    type = "string"
  }

  columns {
    name = "name"
    type = "string"
  }

  columns {
    name = "city"
    type = "string"
  }
 }
}

resource "aws_glue_catalog_table" "parsed" {
 name          = "skills_parsed"
 database_name = aws_glue_catalog_database.myservice_athena_db.name
 description   = "Table containing the results stored in S3 as source"


 table_type = "EXTERNAL_TABLE"


 storage_descriptor {
   location      = "s3://${aws_s3_bucket.bucket.bucket}/parsed"
   input_format  = "org.apache.hadoop.mapred.TextInputFormat"
   output_format = "org.apache.hadoop.hive.ql.io.IgnoreKeyTextOutputFormat"


   ser_de_info {
     name                  = "s3-stream"
     serialization_library = "org.openx.data.jsonserde.JsonSerDe"


     parameters = {
       "ignore.malformed.json" = "TRUE"
       "dots.in.keys"          = "FALSE"
       "case.insensitive"      = "TRUE"
       "mapping"               = "TRUE"
     }
   }

  columns {
    name = "date"
    type = "string"
  }

  columns {
    name = "name"
    type = "string"
  }

  columns {
    name = "city"
    type = "string"
  }
 }
}

