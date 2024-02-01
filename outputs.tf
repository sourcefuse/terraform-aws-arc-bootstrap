output "bucket_arn" {
  value       = aws_s3_bucket.private.arn
  description = "Bucket's ARN"
}

output "bucket_id" {
  value       = aws_s3_bucket.private.id
  description = "Bucket's ID"
}

output "bucket_name" {
  value       = aws_s3_bucket.private.bucket
  description = "Bucket's Name"
}

output "dynamodb_arn" {
  value       = aws_dynamodb_table.terraform_state_lock.arn
  description = "DynamoDB's ARN"
}

output "dynamodb_id" {
  value       = aws_dynamodb_table.terraform_state_lock.id
  description = "DynamoDB's ID"
}

output "dynamodb_name" {
  value       = aws_dynamodb_table.terraform_state_lock.name
  description = "DynamoDB's Name"
}
