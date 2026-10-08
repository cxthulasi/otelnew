(function () {
  var sdk = window.CoralogixRum;
  var log = document.querySelector("[data-event-log]");

  function line(text) {
    if (!log) return;
    var item = document.createElement("li");
    item.textContent = text;
    log.prepend(item);
  }

  if (sdk) sdk.setLabels({ site: "otelnew.com", page: "errors" });

  function handled(label) {
    var error = new Error("Sample checkout total failed to parse");
    error.name = "CheckoutParseError";
    if (sdk) sdk.captureError(error, { field: "total", source: label }, { page: "errors", kind: "handled" });
    line("Handled exception captured (" + label + ").");
  }

  handled("page_load");
  if (sdk) {
    sdk.error("Sample payment authorization failed", { code: "card_declined", attempt: 1 }, { page: "errors" });
    line("Error log sent on page load.");
  }

  var again = document.querySelector("[data-capture]");
  var warn = document.querySelector("[data-warn]");
  var thrown = document.querySelector("[data-throw]");

  if (again) again.addEventListener("click", function () { handled("button"); });
  if (warn) {
    warn.addEventListener("click", function () {
      if (sdk) sdk.warn("Retry budget nearly exhausted", { retries_left: 1 }, { page: "errors" });
      line("Warning log sent.");
    });
  }
  if (thrown) {
    thrown.addEventListener("click", function () {
      try {
        throw new Error("Sample uncaught-style failure, caught by the page");
      } catch (error) {
        if (sdk) sdk.captureError(error, { source: "try_catch" }, { page: "errors", kind: "caught" });
        line("Thrown error was caught and reported. The page stays usable.");
      }
    });
  }
})();
