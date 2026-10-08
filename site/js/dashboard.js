(function () {
  var sdk = window.CoralogixRum;
  var services = [
    { name: "edge-gateway", env: "production", latency: "42ms", errors: "0.1%", status: "healthy" },
    { name: "checkout-api", env: "production", latency: "186ms", errors: "1.8%", status: "degraded" },
    { name: "payments", env: "production", latency: "61ms", errors: "0.2%", status: "healthy" },
    { name: "catalog", env: "production", latency: "74ms", errors: "0.0%", status: "healthy" },
    { name: "postgres", env: "production", latency: "1.4s", errors: "4.6%", status: "failing" },
    { name: "notifications", env: "staging", latency: "110ms", errors: "0.4%", status: "healthy" },
  ];

  var body = document.querySelector("[data-services]");
  var note = document.querySelector("[data-note]");
  var filter = document.querySelector("[data-filter]");
  var refresh = document.querySelector("[data-refresh]");
  var investigate = document.querySelector("[data-investigate]");

  function paint(env) {
    if (!body) return;
    var rows = services.filter(function (service) {
      return env === "all" || service.env === env;
    });
    body.replaceChildren();
    rows.forEach(function (service) {
      var row = document.createElement("tr");
      row.innerHTML =
        "<td>" +
        service.name +
        "</td><td>" +
        service.env +
        '</td><td class="num">' +
        service.latency +
        '</td><td class="num">' +
        service.errors +
        '</td><td><span class="pill pill-' +
        service.status +
        '">' +
        service.status +
        "</span></td>";
      body.appendChild(row);
    });
    if (sdk) sdk.sendCustomMeasurement("dashboard_rows", rows.length);
  }

  function say(message) {
    if (note) note.textContent = message;
  }

  if (sdk) {
    sdk.setLabels({ site: "otelnew.com", page: "dashboard" });
    sdk.addTiming("dashboard_ready");
    sdk.info("dashboard_opened", { services: services.length }, { page: "dashboard" });
  }

  paint("all");

  if (filter) {
    filter.addEventListener("change", function () {
      paint(filter.value);
      if (sdk) sdk.info("dashboard_filter", { env: filter.value }, { page: "dashboard" });
      say("Filtered to " + filter.value + ". A log event was recorded.");
    });
  }

  if (refresh) {
    refresh.addEventListener("click", function () {
      var started = performance.now();
      if (sdk) sdk.startTimeMeasure("dashboard_refresh", { page: "dashboard" });
      say("Refreshing sample services…");
      fetch("https://jsonplaceholder.typicode.com/users?_limit=3")
        .then(function (response) {
          return response.json();
        })
        .then(function (users) {
          var elapsed = Math.round(performance.now() - started);
          if (sdk) {
            sdk.endTimeMeasure("dashboard_refresh");
            sdk.sendCustomMeasurement("dashboard_refresh_ms", elapsed);
          }
          say("Refresh finished in " + elapsed + "ms. Loaded " + users.length + " sample users and recorded a network request.");
        })
        .catch(function (error) {
          if (sdk) sdk.captureError(error, { action: "dashboard_refresh" }, { page: "dashboard" });
          say("The refresh request failed. The error was captured.");
        });
    });
  }

  if (investigate) {
    investigate.addEventListener("click", function () {
      if (sdk) {
        sdk.warn("Investigating postgres pool wait", { service: "postgres", symptom: "pool wait" }, { page: "dashboard" });
      }
      say("Logged a warning for the postgres pool. Check RUM for a warn event.");
    });
  }
})();
