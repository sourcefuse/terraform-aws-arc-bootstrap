################################################
## dynamodb
################################################
variable "dynamodb_name" {
  type        = string
  description = "The name of the table, this needs to be unique within a region."
}

variable "enable_dynamodb_point_in_time_recovery" {
  description = "Whether to enable point-in-time recovery - note that it can take up to 10 minutes to enable for new tables."
  type        = bool
  default     = true
}

variable "dynamodb_hash_key" {
  type        = string
  description = "The attribute to use as the hash (partition) key."
  default     = "LockID"
}

variable "dynamo_kms_master_key_id" {
  type        = string
  description = "The Default ID of an AWS-managed customer master key (CMK) for Amazon Dynamo"
  default     = null
}

################################################
## s3
################################################
## bucket
# variable "abort_incomplete_multipart_upload_days" {
#   description = "Specifies the number of days after initiating a multipart upload when the multipart upload must be completed."
#   type        = number
#   default     = 14
# }

variable "bucket_key_enabled" {
  description = "Whether or not to use Amazon S3 Bucket Keys for SSE-KMS."
  type        = bool
  default     = false
}

variable "bucket_name" {
  type        = string
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

variable "mfa_delete" {
  description = "mfa_delete is disabled"
  type        = bool
  default     = false
}

# variable "expiration" {
#   description = "Specifies a period in the object's expire."
#   type        = list(any)

#   default = [
#     {
#       expired_object_delete_marker = true
#     }
#   ]
# }

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
  type        = string
  description = "The S3 bucket to send S3 access logs."
  default     = ""
}

variable "logging_bucket_target_prefix" {
  type        = string
  description = "To specify a key prefix for log objects."
  default     = ""
}


# variable "noncurrent_version_expiration" {
#   description = "Number of days until non-current version of object expires"
#   type        = number
#   default     = 365
# }

# variable "noncurrent_version_transitions" {
#   description = "Non-current version transition blocks"
#   type        = list(any)

#   default = [
#     {
#       days          = 30
#       storage_class = "STANDARD_IA"
#     }
#   ]
# }

variable "sse_algorithm" {
  description = "The server-side encryption algorithm to use. Valid values are AES256 and aws:kms"
  type        = string
  default     = "AES256"
}

# variable "transitions" {
#   description = "Current version transition blocks"
#   type        = list(any)
#   default     = []
# }

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
    Module           = "terraform-aws-arc-bootstrap"
    TerraformManaged = "true"
  }
}

variable "lifecycle_rules" {
  description = "List of lifecycle rules for the S3 bucket"
  type        = list(object({
    id      = string
    status  = string
    filter  = optional(object({
      prefix = optional(string, null)
      tags   = optional(map(string), {})
    }), {})

    transitions = optional(list(object({
      days          = number
      storage_class = string
    })), [
      {
        days          = 30
        storage_class = "STANDARD_IA"
      },
      {
        days          = 90
        storage_class = "GLACIER"
      }
    ])

    expiration = optional(object({
      days                         = optional(number, 365)
      expired_object_delete_marker = optional(bool, true)
    }), {})

    noncurrent_version_transitions = optional(list(object({
      noncurrent_days = number
      storage_class   = string
    })), [
      {
        noncurrent_days = 30
        storage_class   = "STANDARD_IA"
      },
      {
        noncurrent_days = 90
        storage_class   = "GLACIER"
      }
    ])

    noncurrent_version_expiration = optional(object({
      noncurrent_days = number
    }), {
      noncurrent_days = 365
    })
  }))
  default = [{
    id      = "default-rule"
    status  = "Enabled"
    filter  = {}
    transitions = [
      { days = 30, storage_class = "STANDARD_IA" },
      { days = 90, storage_class = "GLACIER" }
    ]
    expiration = {
      days                         = 365
      expired_object_delete_marker = true
    }
    noncurrent_version_transitions = [
      { noncurrent_days = 30, storage_class = "STANDARD_IA" },
      { noncurrent_days = 90, storage_class = "GLACIER" }
    ]
    noncurrent_version_expiration = {
      noncurrent_days = 365
    }
  }]
}
