################################################
## defaults
################################################
terraform {
  required_version = "~> 1.4"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

################################################
## imports
################################################
data "aws_partition" "current" {}

data "aws_caller_identity" "current" {}

################################################
## iam
################################################
data "aws_iam_policy_document" "policy" {
  ## Enforce SSL/TLS on all objects
  statement {
    sid    = "enforce-tls"
    effect = "Deny"

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    actions = ["s3:*"]

    resources = ["${local.bucket_arn}/*"]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }

  statement {
    sid    = "inventory-and-analytics"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }

    actions   = ["s3:PutObject"]
    resources = ["${local.bucket_arn}/*"]

    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values   = [local.bucket_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
  }
}

################################################
## s3
################################################
resource "aws_s3_bucket" "private" {
  bucket        = var.bucket_name
  acl           = "private"
  policy        = data.aws_iam_policy_document.policy.json
  force_destroy = var.enable_bucket_force_destroy

  tags = merge(var.tags, tomap({
    Name = var.bucket_name,
  }))

  versioning {
    enabled    = var.enable_versioning
    mfa_delete = var.mfa_delete
  }

  lifecycle_rule {
    enabled = true

    abort_incomplete_multipart_upload_days = var.abort_incomplete_multipart_upload_days

    dynamic "expiration" {
      for_each = var.expiration

      content {
        date = lookup(expiration.value, "date", null)
        days = lookup(expiration.value, "days", 0)

        expired_object_delete_marker = lookup(expiration.value, "expired_object_delete_marker", false)
      }
    }

    dynamic "transition" {
      for_each = var.transitions

      content {
        days          = transition.value.days
        storage_class = transition.value.storage_class
      }
    }

    dynamic "noncurrent_version_transition" {
      for_each = var.noncurrent_version_transitions

      content {
        days          = noncurrent_version_transition.value.days
        storage_class = noncurrent_version_transition.value.storage_class
      }
    }

    noncurrent_version_expiration {
      days = var.noncurrent_version_expiration
    }
  }

  lifecycle_rule {
    enabled = true

    prefix = "_AWSBucketInventory/"

    expiration {
      days = 14
    }
  }

  lifecycle_rule {
    enabled = true

    prefix = "_AWSBucketAnalytics/"

    expiration {
      days = 30
    }
  }

  dynamic "logging" {
    for_each = var.enable_bucket_logging ? [1] : []

    content {
      target_bucket = var.logging_bucket_name
      target_prefix = var.logging_bucket_target_prefix
    }
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm     = var.sse_algorithm
        kms_master_key_id = length(var.kms_master_key_id) > 0 ? var.kms_master_key_id : null
      }
      bucket_key_enabled = var.bucket_key_enabled
    }
  }

  dynamic "cors_rule" {
    for_each = var.cors_rules

    content {
      allowed_methods = cors_rule.value.allowed_methods
      allowed_origins = cors_rule.value.allowed_origins
      allowed_headers = lookup(cors_rule.value, "allowed_headers", null)
      expose_headers  = lookup(cors_rule.value, "expose_headers", null)
      max_age_seconds = lookup(cors_rule.value, "max_age_seconds", null)
    }
  }
}

resource "aws_s3_bucket_analytics_configuration" "private_analytics_config" {
  count  = var.enable_analytics ? 1 : 0
  name   = "Analytics"
  bucket = aws_s3_bucket.private.bucket

  storage_class_analysis {
    data_export {
      destination {
        s3_bucket_destination {
          bucket_arn = aws_s3_bucket.private.arn
          prefix     = "_AWSBucketAnalytics"
        }
      }
    }
  }
}

resource "aws_s3_bucket_public_access_block" "public_access_block" {
  count  = var.enable_s3_public_access_block ? 1 : 0
  bucket = aws_s3_bucket.private.id

  ## Block new public ACLs and uploading public objects
  block_public_acls = true

  ## Retroactively remove public access granted through public ACLs
  ignore_public_acls = true

  ## Block new public bucket policies
  block_public_policy = true

  ## Retroactivley block public and cross-account access if bucket has public policies
  restrict_public_buckets = true
}

resource "aws_s3_bucket_inventory" "inventory" {
  count = var.enable_bucket_inventory ? 1 : 0

  bucket = aws_s3_bucket.private.id
  name   = "BucketInventory"

  included_object_versions = "All"

  schedule {
    frequency = var.schedule_frequency
  }

  destination {
    bucket {
      format     = var.inventory_bucket_format
      bucket_arn = aws_s3_bucket.private.arn
      prefix     = "_AWSBucketInventory/"
    }
  }

  optional_fields = [
    "Size",
    "LastModifiedDate",
    "StorageClass",
    "ETag",
    "IsMultipartUploaded",
    "ReplicationStatus",
    "EncryptionStatus",
    "ObjectLockRetainUntilDate",
    "ObjectLockMode",
    "ObjectLockLegalHoldStatus",
    "IntelligentTieringAccessTier"
  ]
}

################################################
## dynamodb
################################################
resource "aws_dynamodb_table" "terraform_state_lock" {
  name           = var.dynamodb_name
  hash_key       = var.dynamodb_hash_key
  read_capacity  = 2
  write_capacity = 2

  server_side_encryption {
    enabled     = true
    kms_key_arn = local.dynamo_kms_master_key_id
  }

  attribute {
    name = var.dynamodb_hash_key
    type = "S"
  }

  point_in_time_recovery {
    enabled = var.enable_dynamodb_point_in_time_recovery
  }

  tags = merge(var.tags, tomap({
    Name = var.dynamodb_name,
  }))
}
