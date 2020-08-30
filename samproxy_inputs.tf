variable "samproxy_accepted_api_keys" {
  description = "The list of Honeycomb API keys that the proxy will accept"
  type        = list(string)
  default = [
    "*",
  ]
}

variable "samproxy_send_delay" {
  description = "The delay to wait after a trace is complete, before sending"
  default     = "2s"
}

variable "samproxy_trace_timeout" {
  description = "The amount of time to wait for a trace to be completed before sending"
  default     = "60s"
}

variable "samproxy_log_level" {
  description = "The Samproxy log level"
  default     = "debug"
}

variable "samproxy_upstream_buffer_size" {
  description = "The number of events to buffer before sending to Honeycomb"
  default     = 10000
}

variable "samproxy_peer_buffer_size" {
  description = "The number of events to buffer before seding to peers"
  default     = 10000
}

variable "samproxy_send_ticker" {
  description = "The duration to use to check for traces to send"
  default     = "100ms"
}

variable "samproxy_cache_capacity" {
  description = "The number of spans to cache"
  default     = 1000
}

variable "samproxy_logger_option" {
  description = "The loger option for samproxy"
  default     = "logrus"

  validation {
    condition = (
      var.samproxy_logger_option == "honeycomb"
      || var.samproxy_logger_option == "logrus"
    )
    error_message = "The samproxy_logger_option value must be \"honeycomb\" or \"logrus\"."
  }
}

variable "samproxy_logger_api_key" {
  description = "The API key to use to send Samproxy logs to Honeycomb"
  default     = ""
}

variable "samproxy_logger_dataset_name" {
  description = "The dataset to which to send Samproxy logs to"
  default     = "Samproxy Logs"
}

variable "samproxy_metrics_api_key" {
  description = "The API key used to send Samproxy metrics to Honeycomb"
  default     = ""
}

variable "samproxy_metrics_option" {
  description = "The metrics option for samproxy"
  default     = "prometheus"

  validation {
    condition = (
      var.samproxy_metrics_option == "honeycomb"
      || var.samproxy_metrics_option == "prometheus"
    )
    error_message = "The samproxy_metrics_option value must be \"honeycomb\" or \"prometheus\"."
  }
}

variable "samproxy_metrics_dataset" {
  description = "The dataset to which to send Samproxy metrics to"
  default     = "Samproxy Metrics"
}

variable "samproxy_metrics_reporting_interval" {
  description = "The interval( in seconds) to wait between sending metrics to Honeycomb"
  default     = 3
}

variable "samproxy_sampler_configs" {
  description = "The Samproxy sampling rules configuration"
  type = list(
    object(
      {
        dataset_name = string
        options      = list(map(string))
      }
    )
  )

  default = [
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
  ]
}
