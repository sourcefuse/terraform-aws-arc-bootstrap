################################################################
## shared
################################################################
variable "region" {
  description = "Region the resources will live in."
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Name of the Dynamo DB lock table."
  type        = string
  default     = "dev"
}

################################################################
## s3
################################################################
variable "bucket_name" {
  description = "Name of the bucket."
  type        = string
}

################################################################
## dynamodb
################################################################
variable "dynamodb_name" {
  description = "Name of the Dynamo DB lock table."
  type        = string
}

variable "dynamo_kms_master_key_id" {
  type        = string
  description = "The Default ID of an AWS-managed customer master key (CMK) for Amazon Dynamo"
  default     = null
}
