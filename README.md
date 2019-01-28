# cloud-custodian-docker

## Why?

To provide a standalone containerized runtime for Capital One's [Cloud Custodian](https://www.capitalone.io/) project.  Maik Ellerbrock already provides a [great implementation](https://github.com/ellerbrock/alpine-cloud-custodian) as well, but mine differs on two points:

1.  The policy and mailer configs are baked into the container image, and
2.  `c7n-mailer` is configured in the container and available for use

Both of these points arose as key considerations when recently implementing Custodian to run on AWS Batch for a client.  I didn't want policies separate from the container lifecycle, so keeping these two things together (e.g. the Dockerfile and the policy) made sense from a CI/CD perspective.  On the second point, I wanted `c7n-mailer` hooked up, and I wanted to be able to use from the same container instance/run as the primary `custodian` runtime.

That said, this isn't intended as a "better" implementation, just one that suits my needs.  Also, this is a from-scratch recreation of functionality for my recent client project, as the client owns the original work product -- in this case, that's a good thing, as I intend to provide full Terraform code to hook this image into AWS Batch and Terraform to establish all the necessary prerequisite resources (S3 bucket, SQS queue, etc.) for Custodian to run successfully in an account.


## Usage

### AWS Account - First-Time Setup

- set up an email to send from in SES in whatever AWS region you'll be deploying into.  Set the email address as the `mail_from` variable (`terraform/terraform.example.tfvars` file).
- `$ chmod +x terraform/tf`
- set `AWS_PROFILE` or `AWS_ACCESS_KEY_ID`/`AWS_SECRET_ACCESS_KEY` environment variables
- `cd terraform`
- Remove `.example` from any files that include it in the name, and replace the example values with values appropriate to your implementation.
- `$ . ./tf init {region}` (`{region}` being whatever AWS region you want to run in)
- `$ terraform plan`
- `$ terraform apply`
- The `init` module sets up an S3 bucket for receiving Custodian output, some IAM elements, and an SQS queue for the mailer.  The `batch` module sets up an ECR repo, IAM elements, and all of the AWS Batch elements necessary to run Custodian in a container.


### Docker - First-Time Setup

- Move the `{policy,mailer}.example.yml` files to `policy.yml` and `mailer.yml` files.
- Edit the YAML files, adding values appropriate to your account/setup.

### Docker - Building/Updating Images

*Run terraform commands above first!*

- `make dkr-deps`
- `make dkr-build`
- `make dkr-clean`
- Still authenticated (e.g. `AWS_PROFILE` or `AWS_ACCESS_KEY_ID`/`AWS_SECRET_ACCESS_KEY`), `make dkr-push-latest` will push your locally built container to your new ECR repo.  This must happen at least once before attempting to run the job through AWS Batch.

### Docker - Running

Using the provided `Makefile`, you can run this container locally.  You need to set the `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, and `AWS_DEFAULT_REGION` environment variables to do so.  You also need a `./logs` directory present.  Steps to run:

- `mkdir logs`
- export AWS_* env variables.
- `make cust-lambda` (this sets up the Lambda for the mailer)
- `make cust-run` (this runs custodian and the mailer)