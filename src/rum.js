import { CoralogixRum } from "@coralogix/browser";

const proxyUrl = "https://rum.otelnew.com/rum";
const page = (location.pathname.split("/").pop() || "index.html").replace(/\.html$/, "") || "index";

CoralogixRum.init({
  public_key: __RUM_PUBLIC_KEY__,
  coralogixDomain: "AP1",
  application: "otelnew",
  version: "1.2.0",
  proxyUrl,
  sessionConfig: {
    keepSessionAfterReload: true,
  },
  sessionRecordingConfig: {
    enable: true,
    autoStartSessionRecording: true,
    recordConsoleEvents: true,
    sessionRecordingSampleRate: 100,
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
