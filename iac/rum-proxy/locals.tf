locals {
  name            = "otelnew-rum-proxy"
  application     = "rum-proxy"
  subsystem       = var.hostname
  rum_ingress     = "ingress.ap1.rum-ingress-coralogix.com"
  cx_domain       = "ap1.coralogix.com"
  proxy_url       = "https://${var.hostname}/rum"
  allowed_origins = join("\n", [for origin in var.browser_origins : "    \"${origin}\": true,"])
}
