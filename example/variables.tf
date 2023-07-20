################################################################
## shared
################################################################
variable "bucket_name" {
  description = "Name of the bucket."
  type        = string
}

variable "dynamodb_name" {
  description = "Name of the Dynamo DB lock table."
  type        = string
}

variable "environment" {
  description = "Name of the Dynamo DB lock table."
  type        = string
  default     = "dev"
}

variable "dynamo_kms_master_key_id" {
  type        = string
  description = "The Default ID of an AWS-managed customer master key (CMK) for Amazon Dynamo"
  default     = null
}
