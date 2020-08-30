# Terraform module for Fargate Samproxy

[![GitHub License: MIT](https://img.shields.io/badge/License-MIT-blue?style=flat-square)](https://opensource.org/licenses/MIT)
[![Gitpod: ready-to-code](https://img.shields.io/badge/Gitpod-ready--to--code-blue?logo=gitpod&style=flat-square)](https://gitpod.io/from-referrer/)
[![Maintenence status: best-effort](https://img.shields.io/badge/Maintained%3F-best--effort-yellow?style=flat-square)](https://github.com/vlaaaaaaad/terraform-aws-fargate-samproxy/pulse)

## Introduction

[Samproxy](https://github.com/honeycombio/samproxy) is a proxy from [Honeycomb](https://www.honeycomb.io) which offers trace-aware sampling.

This module contains the Terraform infrastructure code that creates the required AWS resources to run [Samproxy](https://github.com/honeycombio/samproxy) in AWS, including the following:

- A **V**irtual **P**rivate **C**loud (VPC)
- A SSL certificate using **A**mazon **C**ertificate **M**anager (ACM)
- An **A**pplication **L**oad **B**alancer (ALB)
- A DNS Record using AWS Route53 which points to ALB
- An [AWS **E**lastic **C**loud **S**ervice (ECS)](https://aws.amazon.com/ecs/) Cluster leveraging Spot [AWS Fargate](https://aws.amazon.com/fargate/) to run the Samproxy Docker image
- Two Parameters in [AWS Systems Manager Parameter Store](https://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-parameter-store.html) to store the Samproxy configuration and rules and access them natively in Fargate
- A single-node Redis (cluster mode disabled) Cluster in [AWS ElastiCache](https://aws.amazon.com/elasticache/) to be used by Samproxy for high-availability and peer discovery

![Diagram showing the architecure. The Honeycomb-instrumented apps use Route53 to connect to the ALB. The ALB routes traffic to samproxy containers running in Fargate, in different AZs and public subnets. The Samproxy containers connect to a single-AZ Redis and communicate between them.](./assets/diagram.svg)

## Gotchas

Due to Fargate on ECS having [no support for configuration files](https://github.com/aws/containers-roadmap/issues/56), the configuration is Base64-encoded, stored in [AWS Systems Manager Parameter Store](https://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-parameter-store.html), and then put in the Container Secrets. When Samproxy starts, it decodes the secret and creates the config file on disk. This leads to two limitations:

- configuration files cannot be bigger than 8Kb
- a [custom image](https://github.com/vlaaaaaaad/samproxy-fargate-image) has to be used as the upstream image does not have `sh` or `base64` included

## Versions

This module requires **Terraform 0.13**.

Just like Samproxy, this module is in preview( pre-`0.1`) which means **any new release can have breaking changes**.

## Usage

### As a standalone project

Using this module as a standalone project is **only recommended for testing**.

1. Clone this github repository:

```console
$ git clone git@github.com:vlaaaaaaad/terraform-aws-fargate-samproxy.git

$ cd terraform-aws-fargate-samproxy
```

2. Copy the sample `terraform.tfvars.sample` into `terraform.tfvars` and specify the required variables there.

3. Run `terraform init` to download required providers and modules.

4. Run `terraform apply` to apply the Terraform configuration and create the required infrastructure.

5. Run `terraform output samproxy_url` to get URL where Samproxy is reachable. (Note: It may take a minute or two for the URL to become reachable the first time)

### As a Terraform module

Using this as a Terraform module allows integration with your existing Terraform configurations and pipelines.

```hcl
module "samproxy" {
  # use git to pull the module from GitHub, the latest version
  # source = "git@github.com:vlaaaaaaad/terraform-aws-fargate-samproxy.git?ref=main"
  # or
  # Pull a specific version from Terraform Module Registry
  source  = "Vlaaaaaaad/fargate-samproxy/aws"
  version = "0.0.1"

  # REQUIRED: DNS (without trailing dot)
  route53_zone_name = "example.com"

  # REQUIRED: Samproxy configs
  samproxy_sampler_configs = [
    {
      dataset_name = "_default",
      options = [
        {
          "name"  = "Sampler"
          "value" = "DeterministicSampler"
        },
        {
          "name"  = "SampleRate"
          "value" = 1
        },
      ]
    },
    {
      dataset_name = "my-test-app",
      options = [
        {
          "name"  = "Sampler"
          "value" = "DynamicSampler"
        },
        {
          "name"  = "SampleRate"
          "value" = "2"
        },
        {
          "name"  = "FieldList"
          "value" = "['app.run']"
        },
        {
          "name"  = "UseTraceLength"
          "value" = "true"
        },
        {
          "name"  = "AddSampleRateKeyToTrace"
          "value" = "true"
        },
        {
          "name"  = "AddSampleRateKeyToTraceField"
          "value" = "meta.samproxy.dynsampler_key"
        },
      ]
    },
  ]

  # Optional: override the name
  name = "samproxy"

  # Optional: customize the VPC
  azs                = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
  vpc_cidr           = "10.20.0.0/16"
  vpc_public_subnets = ["10.20.1.0/24", "10.20.2.0/24", "10.20.3.0/24"]

  # Optional: use pre-exiting ACM Certificate instead of creating and validating a new certificate
  certificate_arn = "arn:aws:acm:eu-west-1:135367859851:certificate/70e008e1-c0e1-4c7e-9670-7bb5bd4f5a84"

  # Optional: Send Samproxy logs&metrics to Honeycomb, instead of ECS&nowhere
  samproxy_logger_option   = "honeycomb"
  samproxy_logger_api_key  = "00000000000000000000000000000000"
  samproxy_metrics_option  = "honeycomb"
  samproxy_metrics_api_key = "00000000000000000000000000000000"
}
```

### As a Terraform module, as part of existing infrastructure

Using this module also allows integration with existing AWS resources -- VPC, Subnets, IAM Roles. Specify the required arguments.

> **WARNING**: This was not tested.

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| acm_certificate_arn | The ARN of a certificate issued by AWS ACM. If empty, a new ACM certificate will be created and validated using Route53 DNS | `string` | `""` | no |
| acm_certificate_domain_name | The Route53 domain name to use for ACM certificate. Route53 zone for this domain should be created in advance. Specify if it is different from value in `route53_zone_name` | `string` | `""` | no |
| alb_additional_sgs | A list of additional Security Groups to attach to the ALB | `list(string)` | `[]` | no |
| alb_internal | Whether the load balancer is internal or external | `bool` | `false` | no |
| alb_log_bucket_name | The name of the S3 bucket (externally created) for storing load balancer access logs. Required if `alb_logging_enabled` is true | `string` | `""` | no |
| alb_log_location_prefix | The S3 prefix within the `log_bucket_name` under which logs are stored | `string` | `""` | no |
| alb_logging_enabled | Whether if the ALB will log requests to S3 | `bool` | `false` | no |
| azs | A list of availability zones that you want to use from the Region | `list(string)` | `[]` | no |
| create_route53_record | Whether to create Route53 record for Samproxy | `bool` | `true` | no |
| ecs_capacity_providers | A list of short names or full Amazon Resource Names (ARNs) of one or more capacity providers to associate with the cluster. Valid values also include `FARGATE` and `FARGATE_SPOT` | `list(string)` | <pre>[<br>  "FARGATE_SPOT"<br>]</pre> | no |
| ecs_cloudwatch_log_retention_in_days | The retention time for CloudWatch Logs | `number` | `30` | no |
| ecs_container_memory_reservation | The amount of memory( in MiB) to reserve for Samproxy | `number` | `4096` | no |
| ecs_default_capacity_provider_strategy | The capacity provider strategy to use by default for the cluster. Can be one or more. List of map with corresponding items in docs. See [Terraform Docs](https://www.terraform.io/docs/providers/aws/r/ecs_cluster.html#default_capacity_provider_strategy) | `list(any)` | <pre>[<br>  {<br>    "capacity_provider": "FARGATE_SPOT"<br>  }<br>]</pre> | no |
| ecs_execution_role | The ARN of an existing IAM Role that will be used ECS to start the Tasks | `string` | `""` | no |
| ecs_service_additional_sgs | A list of additional Security Groups to attach to the ECS Service | `list(string)` | `[]` | no |
| ecs_service_assign_public_ip | Whether the ECS Tasks should be assigned a public IP. Should be true, if ECS service is using public subnets. See [AWS Docs](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_cannot_pull_image.html) | `bool` | `true` | no |
| ecs_service_deployment_maximum_percent | The upper limit ( as a percentage of the service's desiredCount) of the number of running tasks that can be running in a service during a deployment | `number` | `300` | no |
| ecs_service_deployment_minimum_healthy_percent | The lower limit ( as a percentage of the service's desiredCount) of the number of running tasks that must remain running and healthy in a service during a deployment | `number` | `100` | no |
| ecs_service_desired_count | The number of instances of the task definition to place and keep running | `number` | `2` | no |
| ecs_service_subnets | If using a pre-existing VPC, subnet IDs to be used for the ECS Service | `list(string)` | `[]` | no |
| ecs_settings | A list of maps with cluster settings. For example, this can be used to enable CloudWatch Container Insights for a cluster. See [Terraform Docs](https://www.terraform.io/docs/providers/aws/r/ecs_cluster.html#setting) | `list(any)` | <pre>[<br>  {<br>    "name": "containerInsights",<br>    "value": "enabled"<br>  }<br>]</pre> | no |
| ecs_task_cpu | The number of CPU units to be used by Samproxy | `number` | `2048` | no |
| ecs_task_memory | The amount of memory( in MiB) to be used by Samprixy | `number` | `4096` | no |
| ecs_task_role | The ARN of an existin IAM Role that will be used by the Samproxy Task | `string` | `""` | no |
| ecs_use_new_arn_format | Whether the AWS Account has opted in to the new longer ARN format which allows tagging ECS | `bool` | `false` | no |
| execution_policies_arn | A list of ARN of the policies to attach to the execution role | `list(string)` | <pre>[<br>  "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy",<br>  "arn:aws:iam::aws:policy/AmazonSSMReadOnlyAccess"<br>]</pre> | no |
| firelens_configuration | The FireLens configuration for the Samproxy container. This is used to specify and configure a log router for container logs. See [AWS Docs](https://docs.aws.amazon.com/AmazonECS/latest/APIReference/API_FirelensConfiguration.html) | <pre>object({<br>    type    = string<br>    options = map(string)<br>  })</pre> | `null` | no |
| image_repository | The Samproxy image repository | `string` | `"vlaaaaaaad/samproxy-fargate-image"` | no |
| image_repository_credentials | The container repository credentials; required when using a private repo.  This map currently supports a single key; `"credentialsParameter"`, which should be the ARN of a Secrets Manager's secret holding the credentials | `map(string)` | `null` | no |
| image_tag | The Samproxy image tag to use | `string` | `"v0.8.0"` | no |
| name | The name to use on all resources created (VPC, ALB, etc) | `string` | `"samproxy"` | no |
| redis_node_type | The instance type used for the Redis cache cluster. See [all available values on the AWS website](https://docs.aws.amazon.com/AmazonElastiCache/latest/red-ug/CacheNodes.SupportedTypes.html) | `string` | `"cache.t2.micro"` | no |
| redis_port | The Redis port | `string` | `"6379"` | no |
| redis_subnets | If using a pre-exiting VPC, subnet IDs to be used for Redis | `list(string)` | `[]` | no |
| redis_version | The Redis version | `string` | `"5.0.6"` | no |
| route53_record_name | The name of Route53 record to create ACM certificate in and main A-record. If `null` is specified, `var.name` is used instead. Provide empty string to point root domain name to ALB | `string` | `null` | no |
| route53_zone_name | The Route53 zone name to create ACM certificate in and main A-record, without trailing dot | `string` | `""` | no |
| samproxy_accepted_api_keys | The list of Honeycomb API keys that the proxy will accept | `list(string)` | <pre>[<br>  "*"<br>]</pre> | no |
| samproxy_cache_capacity | The number of spans to cache | `number` | `1000` | no |
| samproxy_log_level | The Samproxy log level | `string` | `"debug"` | no |
| samproxy_logger_api_key | The API key to use to send Samproxy logs to Honeycomb | `string` | `""` | no |
| samproxy_logger_dataset_name | The dataset to which to send Samproxy logs to | `string` | `"Samproxy Logs"` | no |
| samproxy_logger_option | The loger option for samproxy | `string` | `"logrus"` | no |
| samproxy_metrics_api_key | The API key used to send Samproxy metrics to Honeycomb | `string` | `""` | no |
| samproxy_metrics_dataset | The dataset to which to send Samproxy metrics to | `string` | `"Samproxy Metrics"` | no |
| samproxy_metrics_option | The metrics option for samproxy | `string` | `"prometheus"` | no |
| samproxy_metrics_reporting_interval | The interval( in seconds) to wait between sending metrics to Honeycomb | `number` | `3` | no |
| samproxy_peer_buffer_size | The number of events to buffer before seding to peers | `number` | `10000` | no |
| samproxy_sampler_configs | The Samproxy sampling rules configuration | <pre>list(<br>    object(<br>      {<br>        dataset_name = string<br>        options      = list(map(string))<br>      }<br>    )<br>  )</pre> | <pre>[<br>  {<br>    "dataset_name": "_default",<br>    "options": [<br>      {<br>        "name": "Sampler",<br>        "value": "DeterministicSampler"<br>      },<br>      {<br>        "name": "SampleRate",<br>        "value": 1<br>      }<br>    ]<br>  }<br>]</pre> | no |
| samproxy_send_delay | The delay to wait after a trace is complete, before sending | `string` | `"2s"` | no |
| samproxy_send_ticker | The duration to use to check for traces to send | `string` | `"100ms"` | no |
| samproxy_trace_timeout | The amount of time to wait for a trace to be completed before sending | `string` | `"60s"` | no |
| samproxy_upstream_buffer_size | The number of events to buffer before sending to Honeycomb | `number` | `10000` | no |
| tags | A mapping of tags to assign to all resources | `map(string)` | `{}` | no |
| vpc_alb_subnets | If using a pre-exiting VPC, subnet IDs to be used for the ALBs | `list(string)` | `[]` | no |
| vpc_cidr | The CIDR block for the VPC which will be created if `vpc_id` is not specified | `string` | `"172.16.0.0/16"` | no |
| vpc_id | The ID of an existing VPC where resources will be created | `string` | `""` | no |
| vpc_public_subnets | A list of public subnets inside the VPC | `list(string)` | <pre>[<br>  "172.16.0.0/18",<br>  "172.16.64.0/18",<br>  "172.16.128.0/18"<br>]</pre> | no |

## Outputs

| Name | Description |
|------|-------------|
| alb_dns_name | The DNS name of the ALB |
| alb_sg | The ID of the Security Group attached to the ALB |
| alb_zone_id | The ID of the Route53 zone containing the ALB record |
| ecs_cluster_id | The ARN of the ECS cluster hosting Samproxy |
| samproxy_ecs_security_group | The ID of the Security group assigned to the Samproxy ECS Service |
| samproxy_ecs_task_definition | The task definition for the Samproxy ECS service |
| samproxy_execution_role_arn | The IAM Role used to create the Samproxy tasks |
| samproxy_task_role_arn | The Atlantis ECS task role name |
| samproxy_url | The URL to use for Samproxy |
| vpc_id | The ID of the VPC that was created or passed in |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

## Authors

This module is created and maintained by [Vlad Ionescu](https://github.com/vlaaaaaaad).

This module was inspired by [Anton Babenko's](https://github.com/antonbabenko) [terraform-aws-atlantis](https://github.com/terraform-aws-modules/terraform-aws-atlantis), which was, in turn, inspired by [Seth Vargo's](https://github.com/sethvargo) [atlantis-on-gke](https://github.com/sethvargo/atlantis-on-gke). Yay, open-source!

## License

MIT licensed. See [LICENSE](./LICENSE) details.
