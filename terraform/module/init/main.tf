data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

resource "aws_sqs_queue" "c7n_mailer" {
  name                      = "c7n-mailer"
  delay_seconds             = 30
  max_message_size          = 262144
  message_retention_seconds = 86400
  receive_wait_time_seconds = 10

  kms_master_key_id                 = "alias/aws/sqs"
  kms_data_key_reuse_period_seconds = 300

  tags = "${merge(
      local.common_tags,
      var.custom_tags
    )}"
}

resource "aws_s3_bucket" "c7n_logs" {
  bucket = "c7n-logs-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.name}-${var.env}"
  acl    = "private"

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = "alias/aws/s3"
        sse_algorithm     = "aws:kms"
      }
    }
  }

  lifecycle_rule {
    id      = "base_prefix"
    enabled = true

    prefix = "/"

    tags = {
      "rule"      = "base_prefix"
      "autoclean" = "true"
    }

    transition {
      days          = 60
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 120
      storage_class = "GLACIER"
    }

    expiration {
      days = 180
    }
  }

  tags = "${merge(
      local.common_tags,
      var.custom_tags
    )}"
}

resource "aws_iam_role" "c7n_mailer" {
  name = "c7n-mailer"
  path = "/c7n/"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

  tags = "${merge(
      local.common_tags,
      var.custom_tags
    )}"
}

resource "aws_iam_policy" "c7n_mailer" {
  name        = "c7n-mailer-policy"
  path        = "/c7n/"
  description = "c7n (Cloud Custodian) Policy"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "sqs:ReceiveMessage",
        "sqs:SendMessage",
        "sqs:DeleteMessage",
        "sqs:ChangeMessageVisibility"

      ],
      "Effect": "Allow",
      "Resource": "${aws_sqs_queue.c7n_mailer.arn}"
    },
    {
      "Action": [
        "ses:SendRawEmail"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:ses:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:identity/${var.mail_from}"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "c7n_mailer" {
  role       = "${aws_iam_role.c7n_mailer.name}"
  policy_arn = "${aws_iam_policy.c7n_mailer.arn}"
}
