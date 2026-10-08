(function () {
  var sdk = window.CoralogixRum;
  var list = document.querySelector("[data-requests]");
  var calls = [
    { name: "Catalog user", url: "https://jsonplaceholder.typicode.com/users/1" },
    { name: "Missing post", url: "https://jsonplaceholder.typicode.com/posts/does-not-exist" },
    { name: "Create post", url: "https://jsonplaceholder.typicode.com/posts", method: "POST" },
  ];

  function row(name, status, detail) {
    if (!list) return;
    var item = document.createElement("li");
    item.innerHTML = "<strong>" + name + "</strong><span>" + status + "</span><em>" + detail + "</em>";
    list.appendChild(item);
  }

  function run(call) {
    var started = performance.now();
    var init = call.method === "POST"
      ? { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ title: "otelnew", body: "sample", userId: 1 }) }
      : undefined;
    return fetch(call.url, init)
      .then(function (response) {
        var elapsed = Math.round(performance.now() - started);
        row(call.name, String(response.status), elapsed + "ms · " + call.url);
        if (sdk) sdk.sendCustomMeasurement("network_call_ms", elapsed);
        return response;
      })
      .catch(function (error) {
        row(call.name, "failed", error.message);
        if (sdk) sdk.captureError(error, { url: call.url }, { page: "network" });
      });
  }

  if (sdk) {
    sdk.setLabels({ site: "otelnew.com", page: "network" });
    sdk.info("network_lab_opened", { calls: calls.length }, { page: "network" });
  }

  calls.reduce(function (chain, call) {
    return chain.then(function () { return run(call); });
  }, Promise.resolve());

  var again = document.querySelector("[data-rerun]");
  if (again) {
    again.addEventListener("click", function () {
      if (list) list.replaceChildren();
      calls.forEach(run);
    });
  }
})();
