output "c7n_logs_bucket" {
  value = "${module.init.bucket}"
}

output "c7n_mailer_queue" {
  value = "${module.init.queue}"
}

output "c7n_docker_repo_url" {
  value = "${module.batch.repo_url}"
}
