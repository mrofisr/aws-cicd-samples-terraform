variable "repository_name" {
  description = "Name of the ECR repository."
  type        = string

  validation {
    condition     = length(var.repository_name) > 0
    error_message = "repository_name must not be empty."
  }
}

variable "image_tag_mutability" {
  description = "Tag mutability setting for the repository. Either MUTABLE or IMMUTABLE."
  type        = string
  default     = "MUTABLE"

  validation {
    condition     = contains(["MUTABLE", "IMMUTABLE"], var.image_tag_mutability)
    error_message = "image_tag_mutability must be either MUTABLE or IMMUTABLE."
  }
}

variable "image_scanning_configuration" {
  description = "Image scanning configuration. scan_on_push triggers a vulnerability scan when an image is pushed."
  type = object({
    scan_on_push = bool
  })
  default = {
    scan_on_push = true
  }
}

variable "encryption_configuration" {
  description = "Encryption configuration for the repository. encryption_type is AES256 or KMS; kms_key is required only when using a customer-managed KMS key."
  type = object({
    encryption_type = string
    kms_key         = optional(string)
  })
  default = {
    encryption_type = "AES256"
    kms_key         = null
  }

  validation {
    condition     = contains(["AES256", "KMS"], var.encryption_configuration.encryption_type)
    error_message = "encryption_configuration.encryption_type must be either AES256 or KMS."
  }

  validation {
    condition     = var.encryption_configuration.encryption_type == "KMS" || try(var.encryption_configuration.kms_key, null) == null
    error_message = "encryption_configuration.kms_key may only be set when encryption_type is KMS."
  }
}

variable "lifecycle_policy" {
  description = "Optional lifecycle policy. When null, no lifecycle policy is created. max_image_count expires by image count; max_age_days expires by age. tag_status filters which images the rule applies to (any, tagged, untagged)."
  type = object({
    max_image_count = optional(number)
    max_age_days    = optional(number)
    tag_status      = optional(string, "any")
    tag_prefix_list = optional(list(string), [])
  })
  default = null

  validation {
    condition = (
      var.lifecycle_policy == null
      ? true
      : contains(["any", "tagged", "untagged"], lower(coalesce(var.lifecycle_policy.tag_status, "any")))
    )
    error_message = "lifecycle_policy.tag_status must be one of: any, tagged, untagged."
  }

  validation {
    condition = (
      var.lifecycle_policy == null
      ? true
      : try(var.lifecycle_policy.max_image_count, null) != null || try(var.lifecycle_policy.max_age_days, null) != null
    )
    error_message = "lifecycle_policy must set at least one of max_image_count or max_age_days."
  }

  validation {
    condition = (
      var.lifecycle_policy == null
      ? true
      : lower(coalesce(var.lifecycle_policy.tag_status, "any")) != "tagged" || length(coalesce(var.lifecycle_policy.tag_prefix_list, [])) > 0
    )
    error_message = "lifecycle_policy.tag_prefix_list must be non-empty when tag_status is tagged."
  }
}

variable "enable_repository_policy" {
  description = "Whether to attach a repository policy granting cross-account access to the principals in cross_account_principals."
  type        = bool
  default     = false
}

variable "cross_account_principals" {
  description = "List of IAM principal ARNs (e.g. account roots or roles) granted pull access via the repository policy. Only used when enable_repository_policy is true."
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags to apply to the ECR repository."
  type        = map(string)
  default     = {}
}
