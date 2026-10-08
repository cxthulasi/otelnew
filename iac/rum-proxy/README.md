# otelnew RUM ingest proxy

Terraform for the managed RUM proxy in front of `otelnew.com`.

Browsers send Coralogix RUM to `https://rum.otelnew.com/rum`. A CloudFront distribution tenant presents a managed certificate for that name and forwards only Coralogix browser ingest paths to `ingress.ap1.rum-ingress-coralogix.com`. Caching is off. The viewer request keeps the browser's headers and replaces the Host header with the origin.

Edge access logs go to a Kinesis stream in `ap-south-1`, then to Coralogix AP1 through Coralogix's `firehose-logs` module (`coralogix/aws/coralogix` 4.13.0). That module is vendored in `vendor/firehose-logs` with one change: server-side encryption is omitted when the source is Kinesis, because AWS provider 6 rejects the two settings together. A health check runs every five minutes and the Coralogix Lambda telemetry exporter ships its JSON line to the same application.

## Apply

AWS credentials need permission to create CloudFront, Kinesis, Firehose, Lambda, IAM, Secrets Manager, EventBridge, and S3 (the Firehose module keeps a backup bucket).

```bash
cd iac/rum-proxy
cp terraform.tfvars.example terraform.tfvars
# set coralogix_api_key to the Send-Your-Data key used by the browser SDK
terraform init
terraform apply
```

`terraform.tfvars` is gitignored.

## DNS

After apply, read `cname_target` and add this record in Squarespace. Leave the GitHub Pages apex records and the Google Workspace mail records as they are.

| Type | Host | Value |
| --- | --- | --- |
| CNAME | `rum` | `d1zmcme6cshp8g.cloudfront.net` |

That value is the current `cname_target`. The distribution tenant cannot be created until this record resolves, because CloudFront checks that `rum.otelnew.com` already points at the connection group. After the record is in place, run `terraform apply` again.

CloudFront issues the certificate for `rum.otelnew.com` after that CNAME resolves to the routing endpoint, then attaches it to the tenant. Until both steps finish, browsers cannot open `https://rum.otelnew.com` and no RUM is delivered.

## Alerts

Create these in the Coralogix account, application `rum-proxy`, subsystem `rum.otelnew.com`:

- `dns_ok` is false
- `cert_status` is not `issued`
- `probe_ok` is false
- edge log volume drops to zero while the site is receiving traffic
