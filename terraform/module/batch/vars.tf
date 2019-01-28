variable "project" {
  type = "string"
}

variable "env" {
  type = "string"
}

variable "owner" {
  type = "string"
}

variable "region" {
  type = "string"
}

variable "tfversion" {
  type = "string"
}

variable "tz" {
  type = "string"
}

variable "custom_tags" {
  type = "map"
}

variable "bucket" {
  type = "string"
}

variable "subnets" {
  type = "string"
}

variable "sec_groups" {
  type = "string"
}

variable "mailer_policy_arn" {
  type = "string"
}

locals {
  common_tags {
    Project      = "${var.project}"
    Environment  = "${var.env}"
    OwnerContact = "${var.owner}"
    Provisioner  = "Terraform ${var.tfversion}"
  }
}
