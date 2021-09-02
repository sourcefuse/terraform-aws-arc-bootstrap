output "bucket_arn" {
  value = aws_s3_bucket.private.arn
}

output "bucket_name" {
  value = aws_s3_bucket.private.bucket
}

output "dynamodb_arn" {
  value = aws_dynamodb_table.terraform_state_lock.arn
}

output "dynamodb_name" {
  value = aws_dynamodb_table.terraform_state_lock.name
}
