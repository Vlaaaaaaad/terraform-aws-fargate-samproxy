# Samproxy Config
ListenAddr = "0.0.0.0:8080"
PeerListenAddr = "0.0.0.0:8081"
SendDelay = "${send_delay}"
SendTicker = "${send_ticker}"
TraceTimeout = "${trace_timeout}"
UpstreamBufferSize = ${upstream_buffer_size}
PeerBufferSize = ${peer_buffer_size}
LoggingLevel = "${log_level}"
HoneycombAPI = "https://api.honeycomb.io"
APIKeys = [
  %{ for api_key in accepted_api_keys ~}
  "${api_key}",
  %{ endfor ~}
]

# Implementation Choices
Collector = "InMemCollector"
Logger = "${logger_option}"
Metrics = "${metrics_option}"

[PeerManagement]
Peers = []
Type = "redis"
RedisHost = "${redis_host}"

[InMemCollector]
CacheCapacity = ${cache_capacity}

[LogrusLogger]
# logrus logger currently has no options!

[HoneycombLogger]
LoggerHoneycombAPI = "https://api.honeycomb.io"
LoggerAPIKey = "${logger_api_key}"
LoggerDataset = "${logger_dataset_name}"

[HoneycombMetrics]
MetricsHoneycombAPI = "https://api.honeycomb.io"
MetricsAPIKey = "${metrics_api_key}"
MetricsDataset = "${metrics_dataset}"
MetricsReportingInterval = ${metrics_reporting_interval}

[PrometheusMetrics]
MetricsListenAddr = "localhost:2112"
