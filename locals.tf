locals {
  bucket_arn = "arn:${data.aws_partition.current.partition}:s3:::${var.bucket_name}"
  # dynamo_kms_master_key_id = var.dynamo_kms_master_key_id == null ? "alias/aws/dynamodb" : var.dynamo_kms_master_key_id
}
