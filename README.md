# otelnew

Marketing site for [otelnew](https://otelnew.com), an OpenTelemetry-native observability platform.

The site is static HTML, CSS, and JavaScript in [`site/`](site/). A push to `main` publishes it with GitHub Pages.

## Local preview

```bash
cd site
python3 -m http.server 8765
```

Open http://127.0.0.1:8765/.

## Deployment

[`.github/workflows/pages.yml`](.github/workflows/pages.yml) runs on every push to `main`. It uploads `site/` and deploys to GitHub Pages. No build step.

The contact address used on the site is `hello@otelnew.com`.

## Custom domain

`site/CNAME` sets the Pages domain to `otelnew.com`. Nameservers stay where they are (`ns-cloud-e1` through `ns-cloud-e4.googledomains.com` on Squarespace). Do not change nameservers.

In Squarespace, open the domain → DNS settings. Remove the current website records, then add only the GitHub Pages records below.

Remove:

| Type | Host | Value |
| --- | --- | --- |
| A | `@` | `198.185.159.144` |
| A | `@` | `198.185.159.145` |
| A | `@` | `198.49.23.144` |
| A | `@` | `198.49.23.145` |
| CNAME | `www` | `ext-sq.squarespace.com` |

Do not add the Google forwarding addresses `216.239.32.21`, `216.239.34.21`, `216.239.36.21`, or `216.239.38.21`. Those point the domain at Google, not at this site.

Add:

| Type | Host | Value |
| --- | --- | --- |
| A | `@` | `185.199.108.153` |
| A | `@` | `185.199.109.153` |
| A | `@` | `185.199.110.153` |
| A | `@` | `185.199.111.153` |
| AAAA | `@` | `2606:50c0:8000::153` |
| AAAA | `@` | `2606:50c0:8001::153` |
| AAAA | `@` | `2606:50c0:8002::153` |
| AAAA | `@` | `2606:50c0:8003::153` |
| CNAME | `www` | `cxthulasi.github.io` |

After DNS propagates, enforce HTTPS in the repository Pages settings. GitHub issues the certificate once it sees these records.
