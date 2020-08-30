locals {
  filled_config_file = templatefile(
    "${path.module}/templates/config.toml.tpl",
    {
      accepted_api_keys          = var.samproxy_accepted_api_keys
      send_delay                 = var.samproxy_send_delay
      trace_timeout              = var.samproxy_trace_timeout
      send_ticker                = var.samproxy_send_ticker
      cache_capacity             = var.samproxy_cache_capacity
      upstream_buffer_size       = var.samproxy_upstream_buffer_size
      peer_buffer_size           = var.samproxy_peer_buffer_size
      logger_option              = var.samproxy_logger_option
      log_level                  = var.samproxy_log_level
      logger_api_key             = var.samproxy_logger_api_key
      logger_dataset_name        = var.samproxy_logger_dataset_name
      metrics_api_key            = var.samproxy_metrics_api_key
      metrics_dataset            = var.samproxy_metrics_dataset
      metrics_reporting_interval = var.samproxy_metrics_reporting_interval
      metrics_option             = var.samproxy_metrics_option
      redis_host = join(
        ":",
        [
          aws_elasticache_replication_group.redis.primary_endpoint_address,
          var.redis_port,
        ],
      )
    }
  )

  filled_rules_file = templatefile(
    "${path.module}/templates/rules.toml.tpl",
    {
      samplers = var.samproxy_sampler_configs,
    }
  )
}

resource "aws_ssm_parameter" "config" {
  name        = "/${var.name}/config"
  description = "The Base64-encoded Samproxy configuration"

  type  = "SecureString"
  tier  = "Advanced"
  value = base64encode(local.filled_config_file)

  tags = local.tags
}

resource "aws_ssm_parameter" "rules" {
  name        = "/${var.name}/rules"
  description = "The Base64-encoded Samproxy rules"

  type  = "SecureString"
  tier  = "Advanced"
  value = base64encode(local.filled_rules_file)

  tags = local.tags
}
