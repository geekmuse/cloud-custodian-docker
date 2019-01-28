data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

resource "aws_ecr_repository" "c7n" {
  name = "cloud-custodian"

  tags = "${merge(
      local.common_tags,
      var.custom_tags
    )}"
}

resource "aws_ecr_lifecycle_policy" "c7n_policy" {
  repository = "${aws_ecr_repository.c7n.name}"

  policy = <<EOF
{
    "rules": [
        {
            "rulePriority": 1,
            "description": "Expire untagged images",
            "selection": {
                "tagStatus": "untagged",
                "countType": "sinceImagePushed",
                "countUnit": "days",
                "countNumber": 1
            },
            "action": {
                "type": "expire"
            }
        },
        {
            "rulePriority": 2,
            "description": "Keep last 10 images",
            "selection": {
                "tagStatus": "any",
                "countType": "imageCountMoreThan",
                "countNumber": 10
            },
            "action": {
                "type": "expire"
            }
        }
    ]
}
EOF
}

resource "aws_ecr_repository_policy" "c7n_policy" {
  repository = "${aws_ecr_repository.c7n.name}"

  policy = <<EOF
{
    "Version": "2008-10-17",
    "Statement": [
        {
            "Sid": "BatchServiceUser",
            "Effect": "Allow",
            "Principal": "*",
            "Action": [
                "ecr:GetDownloadUrlForLayer",
                "ecr:BatchGetImage",
                "ecr:BatchCheckLayerAvailability",
                "ecr:DescribeRepositories",
                "ecr:GetRepositoryPolicy",
                "ecr:ListImages"
            ]
        },
        {
            "Sid": "EcrAdmin",
            "Effect": "Allow",
            "Principal": {
              "AWS": "${data.aws_caller_identity.current.user_id}"
            },
            "Action": [
                "ecr:*"
            ]
        }
    ]
}
EOF
}

resource "aws_iam_role" "c7n_batch" {
  name = "c7n-batch"
  path = "/c7n/"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    },
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "batch.amazonaws.com"
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

resource "aws_iam_role_policy" "c7n_batch" {
  name = "c7n-batch"
  role = "${aws_iam_role.c7n_batch.id}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "ec2:Describe*",
        "ec2:CreateTags",
        "ec2:DescribeTags",
        "ec2:DeleteTags",
        "logs:*",
        "s3:*",
        "cloudwatch:*",
        "tag:GetResources",
        "iam:ListAccountAliases"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_instance_profile" "c7n_batch" {
  name = "c7n_batch"
  role = "${aws_iam_role.c7n_batch.name}"
}

resource "aws_iam_role_policy_attachment" "c7n_batch" {
  role       = "${aws_iam_role.c7n_batch.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBatchServiceRole"
}

resource "aws_iam_role_policy_attachment" "c7n_ecs" {
  role       = "${aws_iam_role.c7n_batch.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_role_policy_attachment" "c7n_mailer" {
  role       = "${aws_iam_role.c7n_batch.name}"
  policy_arn = "${var.mailer_policy_arn}"
}

resource "aws_batch_compute_environment" "c7n_batch" {
  compute_environment_name = "c7n_batch"

  compute_resources {
    instance_role = "${aws_iam_instance_profile.c7n_batch.arn}"

    instance_type = [
      "m3.medium",
    ]

    max_vcpus     = 2
    desired_vcpus = 0
    min_vcpus     = 0

    security_group_ids = ["${split(",", var.sec_groups)}"]

    subnets = ["${split(",", var.subnets)}"]

    type = "EC2"
  }

  service_role = "${aws_iam_role.c7n_batch.arn}"
  type         = "MANAGED"
  depends_on   = ["aws_iam_role_policy_attachment.c7n_batch"]
}

resource "aws_batch_job_definition" "c7n_batch" {
  name = "c7n_batch"
  type = "container"

  container_properties = <<CONTAINER_PROPERTIES
{
    "command": ["-c", "/usr/local/bin/custodian run -s s3://${var.bucket}/ policy.yml; /usr/local/bin/c7n-mailer --config mailer.yml --run"],
    "image": "${aws_ecr_repository.c7n.repository_url}:latest",
    "memory": 256,
    "vcpus": 1,
    "volumes": [
      {
        "host": {
          "sourcePath": "/tmp"
        },
        "name": "tmp"
      }
    ],
    "environment": [
        {"name": "TZ", "value": "${var.tz}"},
        {"name": "AWS_DEFAULT_REGION", "value": "${var.region}"}
    ],
    "mountPoints": [
        {
          "sourceVolume": "tmp",
          "containerPath": "/tmp",
          "readOnly": false
        }
    ]
}
CONTAINER_PROPERTIES
}

resource "aws_batch_job_queue" "c7n_batch" {
  name                 = "c7n-batch"
  state                = "ENABLED"
  priority             = 1
  compute_environments = ["${aws_batch_compute_environment.c7n_batch.arn}"]
}
