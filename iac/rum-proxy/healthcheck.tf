data "aws_caller_identity" "current" {}

data "archive_file" "health" {
  type        = "zip"
  source_file = "${path.module}/healthcheck.py"
  output_path = "${path.module}/.build/healthcheck.zip"
}

resource "aws_cloudwatch_log_group" "health" {
  name              = "/aws/lambda/${local.name}-health"
  retention_in_days = 14
}

data "aws_iam_policy_document" "health_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "health" {
  statement {
    effect    = "Allow"
    actions   = ["secretsmanager:GetSecretValue"]
    resources = [aws_secretsmanager_secret.api_key.arn]
  }

  statement {
    effect  = "Allow"
    actions = ["cloudfront:GetManagedCertificateDetails"]
    resources = [
      aws_cloudfront_distribution_tenant.this.arn,
      "arn:aws:cloudfront::${data.aws_caller_identity.current.account_id}:distribution-tenant/${aws_cloudfront_distribution_tenant.this.id}",
    ]
  }
}

resource "aws_iam_role" "health" {
  name               = "${local.name}-health"
  assume_role_policy = data.aws_iam_policy_document.health_assume.json
}

resource "aws_iam_role_policy" "health" {
  name   = "${local.name}-health"
  role   = aws_iam_role.health.id
  policy = data.aws_iam_policy_document.health.json
}

resource "aws_iam_role_policy_attachment" "health_logs" {
  role       = aws_iam_role.health.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_function" "health" {
  function_name    = "${local.name}-health"
  role             = aws_iam_role.health.arn
  runtime          = "python3.13"
  handler          = "healthcheck.main"
  filename         = data.archive_file.health.output_path
  source_code_hash = data.archive_file.health.output_base64sha256
  timeout          = 20
  memory_size      = 256
  architectures    = ["x86_64"]
  layers           = [var.telemetry_exporter_layer_arn]

  environment {
    variables = {
      HOSTNAME              = var.hostname
      EXPECTED_CNAME        = aws_cloudfront_connection_group.this.routing_endpoint
      TENANT_ID             = aws_cloudfront_distribution_tenant.this.id
      PROBE_URL             = local.proxy_url
      CX_DOMAIN             = local.cx_domain
      CX_SECRET             = aws_secretsmanager_secret.api_key.name
      CX_APPLICATION        = local.application
      CX_SUBSYSTEM          = local.subsystem
      CX_REPORTING_STRATEGY = "report_after_invocation"
    }
  }

  depends_on = [
    aws_cloudwatch_log_group.health,
    aws_iam_role_policy_attachment.health_logs,
    aws_secretsmanager_secret_version.api_key,
  ]
}

resource "aws_cloudwatch_event_rule" "health" {
  name                = "${local.name}-health"
  description         = "Probe the otelnew RUM proxy every five minutes."
  schedule_expression = "rate(5 minutes)"
}

resource "aws_cloudwatch_event_target" "health" {
  rule = aws_cloudwatch_event_rule.health.name
  arn  = aws_lambda_function.health.arn
}

resource "aws_lambda_permission" "health" {
  statement_id  = "AllowEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.health.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.health.arn
}
