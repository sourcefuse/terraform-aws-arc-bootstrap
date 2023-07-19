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
