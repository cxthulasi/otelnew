variable "hostname" {
  description = "Proxy hostname the browser SDK calls. Add this as a CNAME in Squarespace."
  type        = string
  default     = "rum.otelnew.com"
}

variable "coralogix_region" {
  description = "Coralogix region code. Must match the browser SDK coralogixDomain."
  type        = string
  default     = "AP1"

  validation {
    condition     = var.coralogix_region == "AP1"
    error_message = "This stack is built for AP1 (ap-south-1). Change the provider region before using another Coralogix region."
  }
}

variable "coralogix_api_key" {
  description = "Send-Your-Data key. Same value as the browser SDK public_key. Stored in Secrets Manager and passed to the Firehose module."
  type        = string
  sensitive   = true
}

variable "browser_origins" {
  description = "Page origins allowed to call the proxy."
  type        = list(string)
  default = [
    "https://otelnew.com",
    "https://www.otelnew.com",
    "https://cxthulasi.github.io",
  ]
}

variable "telemetry_exporter_layer_arn" {
  description = "Coralogix Lambda telemetry exporter layer for ap-south-1, x86_64."
  type        = string
  default     = "arn:aws:lambda:ap-south-1:625240141681:layer:coralogix-aws-lambda-telemetry-exporter-x86_64:38"
}
