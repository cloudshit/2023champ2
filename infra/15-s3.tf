resource "aws_s3_bucket" "bucket" {
  bucket = "skills-1234-kinesis-output"
}

resource "aws_s3_object" "object" {
  bucket = aws_s3_bucket.bucket.id
  key    = "scripts/agent.json"
  source = "../scripts/agent.json"
  etag = filemd5("../scripts/agent.json")
}

resource "aws_s3_object" "object2" {
  bucket = aws_s3_bucket.bucket.id
  key    = "scripts/generator.sh"
  source = "../scripts/generator.sh"
  etag = filemd5("../scripts/generator.sh")
}

resource "aws_s3_object" "object3" {
  bucket = aws_s3_bucket.bucket.id
  key    = "scripts/generator.service"
  source = "../scripts/generator.service"
  etag = filemd5("../scripts/generator.service")
}

