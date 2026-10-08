import { CoralogixRum } from "@coralogix/browser";

const proxyUrl = "https://rum.otelnew.com/rum";

CoralogixRum.init({
  public_key: "cxtp_kxg6Whug9N5V8RcCIUjA1tFwV7Xi9p",
  coralogixDomain: "AP1",
  application: "otelnew",
  version: "1.0.0",
  proxyUrl,
  sessionConfig: {
    keepSessionAfterReload: true,
  },
  labels: {
    site: "otelnew.com",
  },
  sdkFetchPriority: "low",
  collectIPData: true,
  stringifyCustomLogData: true,
  ignoreUrls: [/rum\.otelnew\.com/, /rum-ingress-coralogix\.com/, /ingress\..*\.coralogix\.com/],
});
