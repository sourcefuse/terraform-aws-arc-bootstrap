################################################
## dynamodb
################################################
variable "dynamodb_name" {
  description = "The name of the table, this needs to be unique within a region."
}

variable "enable_dynamodb_point_in_time_recovery" {
  description = "Whether to enable point-in-time recovery - note that it can take up to 10 minutes to enable for new tables."
  type        = bool
  default     = false
}

variable "dynamodb_hash_key" {
  description = "The attribute to use as the hash (partition) key."
  default     = "LockID"
}

################################################
## s3
################################################
## bucket
variable "abort_incomplete_multipart_upload_days" {
  description = "Specifies the number of days after initiating a multipart upload when the multipart upload must be completed."
  type        = number
  default     = 14
}

variable "bucket_key_enabled" {
  description = "Whether or not to use Amazon S3 Bucket Keys for SSE-KMS."
  type        = bool
  default     = false
}

variable "bucket_name" {
  description = "The name of the bucket."
}

variable "cors_rules" {
  description = "List of maps containing rules for Cross-Origin Resource Sharing."
  type        = list(any)
  default     = []
}

variable "enable_bucket_force_destroy" {
  description = "A boolean that indicates all objects (including any locked objects) should be deleted from the bucket so that the bucket can be destroyed without error."
  type        = bool
  default     = false
}

variable "enable_bucket_logging" {
  description = "Enable bucket activity logging."
  type        = bool
  default     = false
}

variable "enable_versioning" {
  description = "Enable versioning. Once you version-enable a bucket, it can never return to an unversioned state."
  type        = bool
  default     = true
}

variable "expiration" {
  description = "Specifies a period in the object's expire."
  type        = list(any)

  default = [
    {
      expired_object_delete_marker = true
    }
  ]
}

variable "inventory_bucket_format" {
  description = "The format for the inventory file. Default is ORC. Options are ORC or CSV."
  type        = string
  default     = "ORC"
}


variable "kms_master_key_id" {
  description = "The AWS KMS master key ID used for the SSE-KMS encryption."
  type        = string
  default     = ""
}

variable "logging_bucket_name" {
  description = "The S3 bucket to send S3 access logs."
  default     = ""
}

variable "logging_bucket_target_prefix" {
  description = "To specify a key prefix for log objects."
  default     = ""
}


variable "noncurrent_version_expiration" {
  description = "Number of days until non-current version of object expires"
  type        = number
  default     = 365
}

variable "noncurrent_version_transitions" {
  description = "Non-current version transition blocks"
  type        = list(any)

  default = [
    {
      days          = 30
      storage_class = "STANDARD_IA"
    }
  ]
}

variable "sse_algorithm" {
  description = "The server-side encryption algorithm to use. Valid values are AES256 and aws:kms"
  type        = string
  default     = "AES256"
}

variable "transitions" {
  description = "Current version transition blocks"
  type        = list(any)
  default     = []
}

## analytics configuration
variable "enable_analytics" {
  description = "Enables storage class analytics on the bucket."
  default     = true
  type        = bool
}

## public access
variable "enable_s3_public_access_block" {
  description = "Bool for toggling whether the s3 public access block resource should be enabled."
  type        = bool
  default     = true
}

## inventory
variable "enable_bucket_inventory" {
  description = "If set to true, Bucket Inventory will be enabled."
  type        = bool
  default     = false
}

variable "schedule_frequency" {
  description = "The S3 bucket inventory frequency. Defaults to Weekly. Options are 'Weekly' or 'Daily'."
  type        = string
  default     = "Weekly"
}

## tags
variable "tags" {
  description = "A mapping of tags to assign to the bucket."
  type        = map(string)

  default = {
    Module           = "terraform-module-aws-bootstrap"
    TerraformManaged = "true"
  }
}
