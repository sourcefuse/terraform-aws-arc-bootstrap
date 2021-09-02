locals {
  bucket_arn = "arn:${data.aws_partition.current.partition}:s3:::${var.bucket_name}"

  datetime = formatdate("YYYYMMDD hh:mm:ss ZZZ", timestamp())
}
