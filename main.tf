################################################
## defaults
################################################
terraform {
  required_version = ">= 1.4, < 2.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0, < 6.0.0"
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
  force_destroy = var.enable_bucket_force_destroy

  tags = merge(var.tags, tomap({
    Name = var.bucket_name,
  }))
}

resource "aws_s3_bucket_policy" "private" {
  bucket = aws_s3_bucket.private.id
  policy = data.aws_iam_policy_document.policy.json
}

resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.private.id
  versioning_configuration {
    status     = var.enable_versioning ? "Enabled" : "Disabled"
    mfa_delete = var.mfa_delete ? "Enabled" : "Disabled"
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

resource "aws_s3_bucket_lifecycle_configuration" "this" {
  bucket =  aws_s3_bucket.private.id

  dynamic "rule" {
    for_each = var.lifecycle_rules
    content {
      id      = rule.value.id
      status  = rule.value.status

      dynamic "filter" {
        for_each = (rule.value.filter != null && (lookup(rule.value.filter, "prefix", null) != null || length(lookup(rule.value.filter, "tags", {})) > 0)) ? [rule.value.filter] : []
        content {
          prefix = lookup(filter.value, "prefix", null)

          dynamic "tag" {
            for_each = lookup(filter.value, "tags", {})
            content {
              key   = tag.key
              value = tag.value
            }
          }
        }
      }

      dynamic "transition" {
        for_each = lookup(rule.value, "transitions", [])
        content {
          days          = lookup(transition.value, "days", null)
          storage_class = transition.value.storage_class
        }
      }

      dynamic "expiration" {
        for_each = rule.value.expiration != null ? [rule.value.expiration] : []
        content {
          days                         = lookup(expiration.value, "days", null)
          expired_object_delete_marker = lookup(expiration.value, "expired_object_delete_marker", null)
        }
      }

      dynamic "noncurrent_version_transition" {
        for_each = lookup(rule.value, "noncurrent_version_transitions", [])
        content {
          noncurrent_days = noncurrent_version_transition.value.noncurrent_days
          storage_class   = noncurrent_version_transition.value.storage_class
        }
      }

      dynamic "noncurrent_version_expiration" {
        for_each = rule.value.noncurrent_version_expiration != null ? [rule.value.noncurrent_version_expiration] : []
        content {
          noncurrent_days = noncurrent_version_expiration.value.noncurrent_days
        }
      }
    }
  }
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

resource "aws_s3_bucket_server_side_encryption_configuration" "example" {
  bucket = aws_s3_bucket.private.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = var.sse_algorithm
      kms_master_key_id = length(var.kms_master_key_id) > 0 ? var.kms_master_key_id : null
    }
    bucket_key_enabled = var.bucket_key_enabled
  }
}

resource "aws_s3_bucket_logging" "this" {
  count = var.enable_bucket_logging ? 1 : 0

  bucket = aws_s3_bucket.private.id

  target_bucket = var.logging_bucket_name
  target_prefix = var.logging_bucket_target_prefix

}

resource "aws_s3_bucket_cors_configuration" "this" {
  count  = length(var.cors_rules) > 0 ? 1 : 0
  bucket = aws_s3_bucket.private.id

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

resource "aws_s3_bucket_ownership_controls" "this" {
  bucket = aws_s3_bucket.private.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "this" {
  depends_on = [aws_s3_bucket_ownership_controls.this]

  bucket = aws_s3_bucket.private.id
  acl    = "private"
}
