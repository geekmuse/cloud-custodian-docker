variable "project" {
  type = "string"
}

variable "env" {
  type = "string"
}

variable "owner" {
  type = "string"
}

variable "tfversion" {
  type = "string"
}

variable "mail_from" {
  type = "string"
}

variable "custom_tags" {
  type = "map"
}

locals {
  common_tags {
    Project      = "${var.project}"
    Environment  = "${var.env}"
    OwnerContact = "${var.owner}"
    Provisioner  = "Terraform ${var.tfversion}"
  }
}
