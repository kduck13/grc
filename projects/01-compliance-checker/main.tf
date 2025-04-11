//Terraform script to provision 10 s3 buckets with compliant and non-compliant configurations.

provider "aws" {
  region = "us-east-1"
}

resource "random_id" "suffix" {
  count = 10
  byte_length = 4
}

locals {
  buckets = {
    "0" = {
      name            = "compliant-1-${random_id.suffix[0].hex}"
      versioning      = true
      encrypted       = true
      tags            = { environment = "compliant" }
    }
    "1" = {
      name            = "compliant-2-${random_id.suffix[1].hex}"
      versioning      = true
      encrypted       = true
      tags            = { environment = "compliant" }
    }
    "2" = {
      name            = "unencrypted-no-versioning-${random_id.suffix[2].hex}"
      versioning      = false
      encrypted       = false
      tags            = { environment = "non-compliant" }
    }
    "3" = {
      name            = "compliant-3-${random_id.suffix[3].hex}"
      versioning      = true
      encrypted       = true
      tags            = { environment = "compliant" }
    }
    "4" = {
      name            = "private-unencrypted-1-${random_id.suffix[4].hex}"
      versioning      = false
      encrypted       = false
      tags            = { environment = "non-compliant" }
    }
    "5" = {
      name            = "private-unencrypted-2-${random_id.suffix[5].hex}"
      versioning      = false
      encrypted       = false
      tags            = { environment = "non-compliant" }
    }
    "6" = {
      name            = "public-encrypted-1-${random_id.suffix[6].hex}"
      versioning      = true
      encrypted       = true
      tags            = { environment = "non-compliant" }
    }
    "7" = {
      name            = "compliant-4-${random_id.suffix[7].hex}"
      versioning      = true
      encrypted       = true
      tags            = { environment = "compliant" }
    }
    "8" = {
      name            = "unencrypted-no-versioning-2-${random_id.suffix[8].hex}"
      versioning      = false
      encrypted       = false
      tags            = { environment = "non-compliant" }
    }
    "9" = {
      name            = "compliant-5-${random_id.suffix[9].hex}"
      versioning      = true
      encrypted       = true
      tags            = { environment = "compliant" }
    }
  }
}

resource "aws_s3_bucket" "buckets" {
  for_each = local.buckets
  bucket   = each.value.name
  tags     = each.value.tags
}

resource "aws_s3_bucket_versioning" "versioning" {
  for_each = { for k, v in local.buckets : k => v if v.versioning }

  bucket = aws_s3_bucket.buckets[each.key].id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "encryption" {
  for_each = { for k, v in local.buckets : k => v if v.encrypted }

  bucket = aws_s3_bucket.buckets[each.key].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_ownership_controls" "ownership" {
  for_each = aws_s3_bucket.buckets

  bucket = each.value.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}
