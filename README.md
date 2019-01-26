# cloud-custodian-docker

## Why?

To provide a standalone containerized runtime for Capital One's Cloud Custodian project.  Maik Ellerbrock already provides a [great implementation](https://github.com/ellerbrock/alpine-cloud-custodian) as well, but mine differs on two points:

1.  The policy and mailer configs are baked into the container image, and
2.  `c7n-mailer` is configured in the container and available for use

Both of these points arose as key considerations when recently implementing Custodian to run on AWS Batch for a client.  I didn't want policies separate from the container lifecycle, so keeping these two things together (e.g. the Dockerfile and the policy) made sense from a CI/CD perspective.  On the second point, I wanted `c7n-mailer` hooked up, and I wanted to be able to use from the same container instance/run as the primary `custodian` runtime.

That said, this isn't intended as a "better" implementation, just one that suits my needs.  Also, this is a from-scratch recreation of functionality for my recent client project, as the client owns the original work product -- in this case, that's a good thing, as I intend to provide full Terraform code to hook this image into AWS Batch and Terraform to establish all the necessary prerequisite resources (S3 bucket, SQS queue, etc.) for Custodian to run successfully in an account.


## To Install

`docker pull docker.io/geekmuse/cloud-custodian:0.8.33.0`

(This assumes you have a local Docker client installed.)


## Local Usage

### Building

- Create an SQS queue called `c7n-mailer` in your account.
- Create an IAM role called `c7n-mailer` in your account.  The role can be configured as described [here](https://devops4solutions.com/cloud-custodian-configure-email/) (Terraform will soon be provided here to assist with this configuration).
- Move the `{policy,mailer}.example.yml` files to `policy.yml` and `mailer.yml` files.
- Edit the YAML files, adding values appropriate to your account/setup.
- `make dkr-deps` (from local `Makefile`)
- `make dkr-build` (from local `Makefile`)

### Running

Using the provided `Makefile`, you can run this container locally.  You need to set the `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, and `AWS_DEFAULT_REGION` environment variables to do so.  You also need a `./logs` directory present.  Steps to run:

- `mkdir logs`
- export AWS_* env variables.
- `make cust-lambda` (this sets up the Lambda for the mailer)
- `make cust-run` (this runs custodian and the mailer)