import { CoralogixRum } from "@coralogix/browser";

const proxyUrl = "https://rum.otelnew.com/rum";
const page = (location.pathname.split("/").pop() || "index.html").replace(/\.html$/, "") || "index";

CoralogixRum.init({
  public_key: "cxtp_kxg6Whug9N5V8RcCIUjA1tFwV7Xi9p",
  coralogixDomain: "AP1",
  application: "otelnew",
  version: "1.1.0",
  proxyUrl,
  sessionConfig: {
    keepSessionAfterReload: true,
  },
  labels: {
    site: "otelnew.com",
    page,
  },
  sdkFetchPriority: "low",
  collectIPData: true,
  stringifyCustomLogData: true,
  ignoreUrls: [/rum\.otelnew\.com/, /rum-ingress-coralogix\.com/, /ingress\..*\.coralogix\.com/],
});

window.CoralogixRum = CoralogixRum;

CoralogixRum.info("page_view", { page, path: location.pathname }, { page });
