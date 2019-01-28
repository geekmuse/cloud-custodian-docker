terraform {
  required_version = "= 0.11.11"
  backend          "s3"             {}
}

provider "aws" {
  version = "= 1.57.0"
  region  = "us-east-1"
  alias   = "east"
}

module "init" {
  source = "module/init"

  project     = "${var.project}"
  owner       = "${var.owner}"
  env         = "${var.env}"
  tfversion   = "${var.tfversion}"
  custom_tags = "${var.custom_tags}"
  mail_from   = "${var.mail_from}"

  providers = {
    aws = "aws.east"
  }
}

module "batch" {
  source = "module/batch"

  project           = "${var.project}"
  owner             = "${var.owner}"
  env               = "${var.env}"
  region            = "${var.region}"
  tfversion         = "${var.tfversion}"
  custom_tags       = "${var.custom_tags}"
  bucket            = "${module.init.bucket}"
  subnets           = "${var.subnets}"
  sec_groups        = "${var.sec_groups}"
  mailer_policy_arn = "${module.init.mailer_policy_arn}"
  tz                = "${var.tz}"

  providers = {
    aws = "aws.east"
  }
}
