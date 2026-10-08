resource "aws_kinesis_stream" "edge" {
  name = "${local.name}-edge"

  stream_mode_details {
    stream_mode = "ON_DEMAND"
  }
}

data "aws_iam_policy_document" "edge_logs_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "edge_logs" {
  statement {
    effect = "Allow"
    actions = [
      "kinesis:DescribeStreamSummary",
      "kinesis:DescribeStream",
      "kinesis:PutRecord",
      "kinesis:PutRecords",
    ]
    resources = [aws_kinesis_stream.edge.arn]
  }
}

resource "aws_iam_role" "edge_logs" {
  name               = "${local.name}-edge-logs"
  assume_role_policy = data.aws_iam_policy_document.edge_logs_assume.json
}

resource "aws_iam_role_policy" "edge_logs" {
  name   = "${local.name}-edge-logs"
  role   = aws_iam_role.edge_logs.id
  policy = data.aws_iam_policy_document.edge_logs.json
}

resource "aws_cloudfront_realtime_log_config" "edge" {
  name          = local.name
  sampling_rate = 100
  fields = [
    "timestamp",
    "c-ip",
    "c-ip-version",
    "c-port",
    "c-country",
    "asn",
    "time-to-first-byte",
    "time-taken",
    "sc-status",
    "sc-bytes",
    "sc-content-type",
    "sc-content-len",
    "sc-range-start",
    "sc-range-end",
    "cs-method",
    "cs-protocol",
    "cs-protocol-version",
    "cs-host",
    "cs-uri-stem",
    "cs-uri-query",
    "cs-bytes",
    "cs-user-agent",
    "cs-referer",
    "cs-cookie",
    "cs-accept",
    "cs-accept-encoding",
    "cs-headers",
    "cs-header-names",
    "cs-headers-count",
    "x-edge-location",
    "x-edge-request-id",
    "x-host-header",
    "x-edge-response-result-type",
    "x-edge-result-type",
    "x-edge-detailed-result-type",
    "x-forwarded-for",
    "ssl-protocol",
    "ssl-cipher",
    "fle-encrypted-fields",
    "fle-status",
    "cache-behavior-path-pattern",
    "origin-fbl",
    "origin-lbl",
    "primary-distribution-id",
    "primary-distribution-dns-name",
    "viewer-request-log-data",
    "viewer-response-log-data",
  ]

  endpoint {
    stream_type = "Kinesis"

    kinesis_stream_config {
      role_arn   = aws_iam_role.edge_logs.arn
      stream_arn = aws_kinesis_stream.edge.arn
    }
  }

  depends_on = [aws_iam_role_policy.edge_logs]
}

resource "aws_secretsmanager_secret" "api_key" {
  name        = "otelnew/rum-proxy/send-your-data"
  description = "Plaintext Send-Your-Data key for the RUM proxy health check."
}

resource "aws_secretsmanager_secret_version" "api_key" {
  secret_id     = aws_secretsmanager_secret.api_key.id
  secret_string = var.coralogix_api_key
}

resource "aws_secretsmanager_secret" "firehose_api_key" {
  name        = "otelnew/rum-proxy/firehose-api-key"
  description = "JSON Send-Your-Data key read by the Coralogix Firehose logs integration."
}

resource "aws_secretsmanager_secret_version" "firehose_api_key" {
  secret_id = aws_secretsmanager_secret.firehose_api_key.id
  secret_string = jsonencode({
    api_key = var.coralogix_api_key
  })
}

module "edge_logs" {
  source = "./vendor/firehose-logs"

  firehose_stream       = local.name
  api_key_secret_arn    = aws_secretsmanager_secret.firehose_api_key.arn
  coralogix_region      = var.coralogix_region
  application_name      = local.application
  subsystem_name        = local.subsystem
  source_type_logs      = "KinesisStreamAsSource"
  kinesis_stream_arn    = aws_kinesis_stream.edge.arn
  integration_type_logs = "RawText"
}
