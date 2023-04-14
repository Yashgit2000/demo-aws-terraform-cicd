resource "aws_s3_bucket" "code-pipeline-artifacts1" {
  bucket = "code-pipeline-artifacts1"
}

resource "aws_s3_bucket_acl" "code-pipeline-artifacts1_acl" {
  bucket = aws_s3_bucket.code-pipeline-artifacts1.id
  acl    = "private"
}

resource "aws_s3_bucket" "code-pipeline-artifacts123" {
  bucket = "code-pipeline-artifacts123"
}

resource "aws_s3_bucket_acl" "code-pipeline-artifacts123_acl" {
  bucket = aws_s3_bucket.code-pipeline-artifacts123.id
  acl    = "private"
}
