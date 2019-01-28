output "bucket" {
  value = "${aws_s3_bucket.c7n_logs.id}"
}

output "queue" {
  value = "${aws_sqs_queue.c7n_mailer.name}"
}

output "mailer_policy_id" {
  value = "${aws_iam_policy.c7n_mailer.id}"
}

output "mailer_policy_arn" {
  value = "${aws_iam_policy.c7n_mailer.arn}"
}

output "mailer_poicy_name" {
  value = "${aws_iam_policy.c7n_mailer.name}"
}
