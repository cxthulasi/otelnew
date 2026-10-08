output "proxy_url" {
  description = "Value of proxyUrl in the browser SDK."
  value       = local.proxy_url
}

output "cname_host" {
  description = "Squarespace DNS host for the proxy."
  value       = "rum"
}

output "cname_target" {
  description = "Squarespace CNAME value. Point rum.otelnew.com at this CloudFront routing endpoint."
  value       = aws_cloudfront_connection_group.this.routing_endpoint
}

output "distribution_id" {
  value = aws_cloudfront_multitenant_distribution.this.id
}

output "distribution_tenant_id" {
  value = aws_cloudfront_distribution_tenant.this.id
}
