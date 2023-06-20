resource "aws_cloudwatch_log_group" "main" {
  name = "/aws/kinesisfirehose/dev-skills-firehose" 
}

resource "aws_kinesis_firehose_delivery_stream" "main" {
  name        = "dev-skills-firehose"
  destination = "extended_s3"

  extended_s3_configuration {
    role_arn   = aws_iam_role.firehose_role.arn
    bucket_arn = aws_s3_bucket.bucket.arn
    buffer_interval = 60

    prefix = "parsed/"
    s3_backup_mode = "Enabled"

    cloudwatch_logging_options {
      enabled = true
      log_group_name = "/aws/kinesisfirehose/dev-skills-firehose"
      log_stream_name = "DestinationDelivery" 
    }

    s3_backup_configuration {
      role_arn   = aws_iam_role.firehose_role.arn
      bucket_arn = aws_s3_bucket.bucket.arn
      prefix = "source/"
      buffer_interval = 60

      cloudwatch_logging_options {
        enabled = true
        log_group_name = "/aws/kinesisfirehose/dev-skills-firehose"
        log_stream_name = "BackupDelivery"
      }
    }

    processing_configuration {
      enabled = "true"

      processors {
        type = "Lambda"

        parameters {
          parameter_name  = "LambdaArn"
          parameter_value = "${aws_lambda_function.lambda_processor.arn}:$LATEST"
        }
      }
    }
  }
}

data "aws_iam_policy_document" "firehose_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["firehose.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "firehose_role" {
  name               = "firehose_test_role"
  assume_role_policy = data.aws_iam_policy_document.firehose_assume_role.json
}

resource "aws_iam_policy" "firehose_role" {
  name = "firehose_policy"
  policy = jsonencode({
    Version = "2012-10-17",  
    Statement = [    
      {      
        "Effect": "Allow",      
        "Action": [
          "s3:AbortMultipartUpload",
          "s3:GetBucketLocation",
          "s3:GetObject",
          "s3:ListBucket",
          "s3:ListBucketMultipartUploads",
          "s3:PutObject"
        ],      
        "Resource": [        
          "arn:aws:s3:::${aws_s3_bucket.bucket.id}",
          "arn:aws:s3:::${aws_s3_bucket.bucket.id}/*"		    
        ]    
      },
      {
        "Effect": "Allow",
        "Action": [
          "logs:PutLogEvents"
        ],
        "Resource": [
          "${aws_cloudwatch_log_group.main.arn}:log-stream:*"
        ]
      },
      {
        "Effect": "Allow", 
        "Action": [
          "lambda:InvokeFunction", 
          "lambda:GetFunctionConfiguration" 
        ],
        "Resource": [
          "${aws_lambda_function.lambda_processor.arn}:*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach" {
  role = aws_iam_role.firehose_role.name
  policy_arn = aws_iam_policy.firehose_role.arn
}

data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "lambda_iam" {
  name               = "lambda_iam"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json

  managed_policy_arns = ["arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"]
}

data "archive_file" "lambda" {
  type        = "zip"
  source_file = "../scripts/lambda.js"
  output_path = "../scripts/lambda_function_payload.zip"
}

resource "aws_lambda_function" "lambda_processor" {
  filename      = "../scripts/lambda_function_payload.zip"
  function_name = "skills-firehose-function"
  source_code_hash = data.archive_file.lambda.output_base64sha256
  timeout = 60
  role          = aws_iam_role.lambda_iam.arn
  handler       = "lambda.handler"
  runtime       = "nodejs16.x"
}
