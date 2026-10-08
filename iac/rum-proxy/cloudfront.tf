data "aws_cloudfront_cache_policy" "disabled" {
  name = "Managed-CachingDisabled"
}

data "aws_cloudfront_origin_request_policy" "all_viewer_except_host" {
  name = "Managed-AllViewerExceptHostHeader"
}

resource "aws_cloudfront_function" "request" {
  name    = "${local.name}-request"
  runtime = "cloudfront-js-2.0"
  comment = "Allow only Coralogix RUM ingest paths and rewrite cxforward onto the origin."
  publish = true
  code = templatefile("${path.module}/function-request.js.tftpl", {
    ingress_host    = local.rum_ingress
    allowed_origins = local.allowed_origins
  })
}

resource "aws_cloudfront_function" "response" {
  name    = "${local.name}-response"
  runtime = "cloudfront-js-2.0"
  comment = "Return the site origin on RUM responses so the browser accepts the proxy."
  publish = true
  code = templatefile("${path.module}/function-response.js.tftpl", {
    allowed_origins = local.allowed_origins
  })
}

resource "aws_cloudfront_connection_group" "this" {
  name         = local.name
  enabled      = true
  ipv6_enabled = true
}

resource "aws_cloudfront_multitenant_distribution" "this" {
  comment = "otelnew RUM ingest proxy"
  enabled = true

  origin {
    id          = "rum-ingress"
    domain_name = local.rum_ingress

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  default_cache_behavior {
    target_origin_id       = "rum-ingress"
    viewer_protocol_policy = "https-only"
    cache_policy_id        = data.aws_cloudfront_cache_policy.disabled.id

    allowed_methods {
      items          = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
      cached_methods = ["GET", "HEAD"]
    }
    origin_request_policy_id = data.aws_cloudfront_origin_request_policy.all_viewer_except_host.id
    compress                 = true
    realtime_log_config_arn  = aws_cloudfront_realtime_log_config.edge.arn

    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.request.arn
    }

    function_association {
      event_type   = "viewer-response"
      function_arn = aws_cloudfront_function.response.arn
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  # The customer certificate is requested on the distribution tenant.
  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tenant_config {
    parameter_definition {
      name = "hostname"

      definition {
        string_schema {
          comment  = "Proxy hostname"
          required = true
        }
      }
    }
  }
}

resource "aws_cloudfront_distribution_tenant" "this" {
  distribution_id     = aws_cloudfront_multitenant_distribution.this.id
  connection_group_id = aws_cloudfront_connection_group.this.id
  name                = local.name
  enabled             = true
  wait_for_deployment = true

  domain {
    domain = var.hostname
  }

  managed_certificate_request {
    primary_domain_name                         = var.hostname
    validation_token_host                       = "cloudfront"
    certificate_transparency_logging_preference = "enabled"
  }

  # CloudFront issues the certificate, then the tenant has to reference it
  # before rum.otelnew.com will serve TLS.
  customizations {
    certificate {
      arn = "arn:aws:acm:us-east-1:440027026084:certificate/0ef189fa-9456-4491-befc-5dba107550ca"
    }
  }

  parameter {
    name  = "hostname"
    value = var.hostname
  }
}
