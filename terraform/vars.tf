variable "region" {
  description = "AWS region"
  type        = "string"
  default     = ""
}

variable "owner" {
  description = "Owner description - Email or ID"
  type        = "string"
  default     = ""
}

variable "env" {
  description = "Environment identifier"
  type        = "string"
  default     = ""
}

variable "resource_type" {
  description = "Resource type - global|regional"
  type        = "string"
  default     = ""
}

variable "project" {
  description = "Project"
  type        = "string"
  default     = ""
}

variable "tfversion" {
  description = "Terraform version"
  type        = "string"
  default     = ""
}

variable "tz" {
  description = "Python Timezone Offset String"
  type        = "string"
  default     = "UTC"
}

variable "mail_from" {
  description = "Sent from address for custodian emails (must be set up as a valid sender in SES)"
  type        = "string"
}

variable "custom_tags" {
  description = "Map of custom tags"
  type        = "map"
  default     = {}
}

variable "subnets" {
  description = "Subnets into which to deploy AWS Batch compute environment"
  type        = "string"
  default     = ""
}

variable "sec_groups" {
  description = "Security groups into which to deploy AWS Batch compute environment"
  type        = "string"
  default     = ""
}
